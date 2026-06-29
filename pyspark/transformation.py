from pyspark.sql.functions import *
# from pyspark.sql.functions import col

df.filter(
    ~col("helpful").rlike("^[0-9]*\\.?[0-9]+$")
).show(20, truncate=False)



df_silver = (
    df.withColumnRenamed("asin", "product_id")
      .withColumnRenamed("sentence", "feedback")
      .withColumnRenamed("helpful", "helpful_score")
      .withColumnRenamed("product_title", "product_name")
      .withColumn("helpful_score", col("helpful_score").cast("double"))
)

df_silver.printSchema()

df_silver.select(
    [count(when(col(c).isNull(), c)).alias(c)
     for c in df_silver.columns]
).show()

df_silver = df_silver.withColumn(
    "feedback",
    trim(col("feedback"))
)

df_silver = df_silver.filter(
    col("feedback").isNotNull() &
    (trim(col("feedback")) != "")
)

df_silver = df_silver.withColumn(
    "sentence_length",
    length(col("feedback"))
)

df_silver = df_silver.withColumn(
    "word_count",
    size(split(col("feedback"), " "))
)

df_silver = df_silver.withColumn(
    "ingestion_source",
    lit("Batch")
)

df_silver = df_silver.withColumn(
    "ingestion_timestamp",
    current_timestamp()
)

df_silver.select(
    min("helpful_score"),
    max("helpful_score")
).show()


df_silver = df_silver.withColumn(
    "helpfulness_band",
    when(col("helpful_score") < 0.66, "Low")
    .when(col("helpful_score") < 1.33, "Medium")
    .otherwise("High")
)

df_silver = df_silver.withColumn(
    "score_flag",
    when(
        (col("helpful_score") < 0) |
        (col("helpful_score") > 2),
        "Out Of Range"
    ).otherwise("Valid"b)
)

from pyspark.sql.window import Window

df_silver = df_silver.withColumn(
    "feedback_hash",
    sha2(col("feedback"), 256)
)

window_spec = Window.partitionBy("feedback_hash").orderBy("product_id")

df_silver = (
    df_silver
    .withColumn("rn", row_number().over(window_spec))
    .filter(col("rn") == 1)
    .drop("rn")
)


