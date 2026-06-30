SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'https://stamazonreviewdldev.dfs.core.windows.net/silver/silver_data',
    FORMAT = 'DELTA'
) AS rows;

CREATE SCHEMA gold;

--create view

CREATE OR ALTER VIEW gold.vw_clean_reviews
AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stamazonreviewdldev.dfs.core.windows.net/silver/silver_data',
    FORMAT = 'DELTA'
) AS rows;

--show the view
SELECT TOP 10 * FROM gold.vw_clean_reviews;

-- Create Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssword12345!';

-- Create Database Scoped Credential
CREATE DATABASE SCOPED CREDENTIAL sc_adls_identity
WITH IDENTITY = 'Managed Identity';

-- Create External Data Source
CREATE EXTERNAL DATA SOURCE eds_gold_datalake
WITH (
    LOCATION = 'https://stamazonreviewdldev.dfs.core.windows.net',
    CREDENTIAL = sc_adls_identity
);
CREATE EXTERNAL FILE FORMAT ParquetFormat
WITH (
    FORMAT_TYPE = PARQUET
);

-- Use Case 1: Helpfulness Segmentation

CREATE OR ALTER VIEW gold.HelpfulnessCategory
AS
SELECT
    helpfulness_band,
    COUNT(*) AS review_count,
    AVG(helpfulness_score) AS avg_helpfulness_score,
    AVG(review_length) AS avg_review_length,
    AVG(word_count) AS avg_word_count
FROM gold.vw_clean_reviews
GROUP BY helpfulness_band;
GO

-- Show results
SELECT * FROM gold.HelpfulnessCategory;

-- Use Case 2: Low-Helpfulness Driver Analysis

CREATE OR ALTER VIEW gold.vw_low_helpfulness_drivers
AS
SELECT
    CASE
        WHEN word_count < 5 THEN 'Short Review'
        WHEN review_length < 25 THEN 'Small Sentence'
        ELSE 'Other'
    END AS driver,
    COUNT(*) AS affected_count
FROM gold.vw_clean_reviews
WHERE helpfulness_band = 'Low'
GROUP BY
    CASE
        WHEN word_count < 5 THEN 'Short Review'
        WHEN review_length < 25 THEN 'Small Sentence'
        ELSE 'Other'
    END;
GO

-- Show results
SELECT * FROM gold.vw_low_helpfulness_drivers;


-- Use Case 3: Real-Time Review Intake Monitoring

CREATE OR ALTER VIEW gold.vw_realtime_intake_trend
AS
SELECT
    CAST(ingestion_timestamp AS DATE) AS load_date,
    COUNT(*) AS review_count,
    AVG(helpfulness_score) AS avg_helpfulness_score
FROM gold.vw_clean_reviews
GROUP BY CAST(ingestion_timestamp AS DATE);
GO

-- Show results
SELECT * FROM gold.vw_realtime_intake_trend;


--External Table Creation
CREATE EXTERNAL TABLE gold.ext_helpfulness_category
WITH (
    LOCATION = 'gold/gold_data/helpfulness_category/',
    DATA_SOURCE = eds_gold_datalake,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM gold.HelpfulnessCategory;

CREATE EXTERNAL TABLE gold.ext_low_helpfulness_drivers
WITH (
    LOCATION = 'gold/gold_data/low_helpfulness_drivers/',
    DATA_SOURCE = eds_gold_datalake,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM gold.vw_low_helpfulness_drivers;

CREATE EXTERNAL TABLE gold.ext_realtime_intake_trend
WITH (
    LOCATION = 'gold/gold_data/realtime_intake_trend/',
    DATA_SOURCE = eds_gold_datalake,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM gold.vw_realtime_intake_trend;


