SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'https://storageaccountforetletn.dfs.core.windows.net/silver/silver_Data',
    FORMAT = 'DELTA'
) AS rows;

CREATE SCHEMA gold;

CREATE OR ALTER VIEW gold.vw_review_silver
AS
SELECT *
FROM OPENROWSET(
    BULK 'https://storageaccountforetletn.dfs.core.windows.net/silver/silver_Data',
    FORMAT = 'DELTA'
) AS rows;

SELECT TOP 10 * FROM gold.vw_review_silver;

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





