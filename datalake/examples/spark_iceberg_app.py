from pyspark.sql import SparkSession


def main():
    # Create a Spark session
    spark = SparkSession.builder.appName("Iceberg App") \
        .config('spark.sql.extensions', 'org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions') \
        .config('spark.sql.catalog.spark_catalog', 'org.apache.iceberg.spark.SparkCatalog') \
        .config("spark.sql.catalog.spark_catalog.type", "rest") \
        .config("spark.sql.catalog.spark_catalog.uri", "http://rest:8181") \
        .config("spark.sql.catalog.spark_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO") \
        .config("spark.sql.catalog.spark_catalog.warehouse", "s3://warehouse/") \
        .config("spark.sql.catalog.spark_catalog.s3.endpoint", "http://minio:9000") \
        .config("spark.sql.defaultCatalog", "spark_catalog") \
        .getOrCreate()

    input_df = spark.range(1, 31)
    input_df.write.mode(saveMode="overwrite").format("iceberg").saveAsTable("default.sample")

    output_df = spark.sql("select * from default.sample")
    count = output_df.count()

    print(f"Total Count: {count}")

    # Stop the SparkSession
    spark.stop()


if __name__ == "__main__":
    main()
