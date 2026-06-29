spark.conf.set(
    "fs.azure.account.auth.type.storageaccountforetletn.dfs.core.windows.net",
    "OAuth"
)

spark.conf.set(
    "fs.azure.account.oauth.provider.type.storageaccountforetletn.dfs.core.windows.net",
    "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
)

spark.conf.set(
    "fs.azure.account.oauth2.client.id.storageaccountforetletn.dfs.core.windows.net",
    "250a9215-8fc2-4dbb-8f55-c64f368f7b0d"
)

spark.conf.set(
    "fs.azure.account.oauth2.client.secret.storageaccountforetletn.dfs.core.windows.net",
    "M3V8Q~J1Y4TpH1tH.CHd.fQEgWRT1InowkjJjdqC"
)

spark.conf.set(
    "fs.azure.account.oauth2.client.endpoint.storageaccountforetletn.dfs.core.windows.net",
    "https://login.microsoftonline.com/91aac73c-5d95-4a23-83ef-2b7a7cc295cb/oauth2/token"
)

display(
    dbutils.fs.ls(
        "abfss://bronze@storageaccountforetletn.dfs.core.windows.net/"
    )
)

df = spark.read \
    .format("csv") \
    .option("header", "true") \
    .option("multiLine", "true") \
    .option("quote", '"') \
    .option("escape", '"') \
    .option("mode", "PERMISSIVE") \
    .load("abfss://bronze@storageaccountforetletn.dfs.core.windows.net/RawData")

