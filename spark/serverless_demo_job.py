from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf

with SparkSession.builder.appName("serverless-demo").getOrCreate() as spark:

    @udf(returnType="int")
    def get_content_length(url: str):
        from library_for_spark.user_defined_function import page_content_length

        return page_content_length(url)

    df = spark.createDataFrame(
        [("https://www.google.com", 1), ("https://www.example.com", 2)],
        ["url", "id"],
    )

    df.show()
    lengths = df.withColumn("content_length", get_content_length(col("url")))
    lengths.show()
