SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'https://customerreviewdatalake.dfs.core.windows.net/silver/silver_data',
    FORMAT = 'DELTA'
) AS rows;

CREATE SCHEMA gold;


--Cerating View

CREATE OR ALTER VIEW gold.vw_review_silver
AS
SELECT *
FROM OPENROWSET(
    BULK 'https://customerreviewdatalake.dfs.core.windows.net/silver/silver_data',
    FORMAT = 'DELTA'
) AS rows;

--Showing the View
SELECT TOP 10 * FROM gold.vw_review_silver;


CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password';

CREATE DATABASE SCOPED CREDENTIAL customerreviewidentity
WITH IDENTITY = 'Managed Identity';

CREATE EXTERNAL DATA SOURCE GoldDataLake
WITH (
    LOCATION = 'https://customerreviewdatalake.dfs.core.windows.net',
    CREDENTIAL = customerreviewidentity
);

CREATE EXTERNAL FILE FORMAT ParquetFormat
WITH (
    FORMAT_TYPE = PARQUET
);

-- Use Case 1: Helpfulness Segmentation

CREATE OR ALTER VIEW gold.HelpfulnessSegments
AS
SELECT
    helpfulness_band,
    COUNT(*) AS review_count,
    AVG(helpful_score) AS avg_helpful_score,
    AVG(sentence_length) AS avg_sentence_length,
    AVG(word_count) AS avg_word_count
FROM gold.vw_review_silver
GROUP BY helpfulness_band;
GO

SELECT * FROM gold.HelpfulnessSegments;



-- Use Case 2: Low-Helpfulness Driver Analysis

CREATE OR ALTER VIEW gold.LowHelpfulnessDrivers
AS
SELECT
    CASE
        WHEN word_count < 5 THEN 'Short Review'
        WHEN sentence_length < 25 THEN 'Small Sentence'
        ELSE 'Other'
    END AS driver,
    COUNT(*) AS affected_count
FROM gold.vw_review_silver
WHERE helpfulness_band = 'Low'
GROUP BY
    CASE
        WHEN word_count < 5 THEN 'Short Review'
        WHEN sentence_length < 25 THEN 'Small Sentence'
        ELSE 'Other'
    END;
GO

SELECT * FROM gold.LowHelpfulnessDrivers;


-- Use Case 3: Real-Time Review Intake Monitoring

CREATE OR ALTER VIEW gold.RealtimeIntakeTrend
AS
SELECT
    CAST(ingestion_timestamp AS DATE) AS load_date,
    COUNT(*) AS review_count,
    AVG(helpful_score) AS avg_helpful_score
FROM gold.vw_review_silver
GROUP BY CAST(ingestion_timestamp AS DATE);
GO

SELECT * FROM gold.RealtimeIntakeTrend;



--External Table Creation

CREATE EXTERNAL TABLE HelpfulnessSegments_Export
WITH (
    LOCATION = '/gold/gold_data/helpfulness_segments',
    DATA_SOURCE = GoldDataLake,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM gold.HelpfulnessSegments;


CREATE EXTERNAL TABLE LowHelpfulnessDrivers_Export
WITH (
    LOCATION = '/gold/gold_data/low_helpfulness_drivers',
    DATA_SOURCE = GoldDataLake,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM gold.LowHelpfulnessDrivers;


CREATE EXTERNAL TABLE RealtimeIntakeTrend_Export
WITH (
    LOCATION = '/gold/gold_data/realtime_intake_trend',
    DATA_SOURCE = GoldDataLake,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM gold.RealtimeIntakeTrend;