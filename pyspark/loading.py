silver_path = "abfss://silver@storageaccountforetletn.dfs.core.windows.net/silver_Data"
df_silver.write \
    .format("delta") \
    .mode("overwrite") \
    .save(silver_path)

gold_helpfulness_segments = (
    df_silver
    .groupBy("helpfulness_band")
    .agg(
        count("*").alias("review_count"),
        round(avg("helpful_score"),2).alias("avg_helpful_score"),
        round(avg("sentence_length"),2).alias("avg_sentence_length"),
        round(avg("word_count"),2).alias("avg_word_count")
    )
)

gold_helpfulness_segments.write \
    .format("delta") \
    .mode("overwrite") \
    .save("abfss://gold@storageaccountforetletn.dfs.core.windows.net/HelpfulnessSegments")

gold_low_drivers = (
    df_silver
    .filter(col("helpfulness_band")=="Low")
    .withColumn(
        "driver",
        when(col("word_count") < 5, "Short Review")
        .when(col("sentence_length") < 25, "Small Sentence")
        .otherwise("Other")
    )
    .groupBy("driver")
    .agg(count("*").alias("affected_count"))
)

gold_low_drivers.write \
    .format("delta") \
    .mode("overwrite") \
    .save("abfss://gold@storageaccountforetletn.dfs.core.windows.net/LowHelpfulnessDrivers")


gold_intake_trend = (
    df_silver
    .groupBy(to_date("ingestion_timestamp").alias("load_date"))
    .agg(
        count("*").alias("review_count"),
        round(avg("helpful_score"),2).alias("avg_helpful_score")
    )
)

gold_intake_trend.write \
    .format("delta") \
    .mode("overwrite") \
    .save("abfss://gold@storageaccountforetletn.dfs.core.windows.net/RealtimeIntakeTrend")

display(
    spark.read.format("delta")
    .load("abfss://gold@storageaccountforetletn.dfs.core.windows.net/HelpfulnessSegments")
)


