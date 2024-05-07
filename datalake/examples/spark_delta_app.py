from pyspark.sql import SparkSession
from delta import *


def main():
    # Create a Spark session
    spark = SparkSession.builder.appName("Delta App") \
        .config('spark.sql.extensions', 'io.delta.sql.DeltaSparkSessionExtension') \
        .config('spark.sql.catalog.spark_catalog', 'org.apache.spark.sql.delta.catalog.DeltaCatalog') \
        .getOrCreate()

    input_df = spark.range(1, 31)
    input_df.write.mode(saveMode="overwrite").format("delta").save("/tmp/delta-table")

    output_df = spark.read.format("delta").load("/tmp/delta-table")
    count = output_df.count()

    print(f"Total Count: {count}")

    # Stop the SparkSession
    spark.stop()


if __name__ == "__main__":
    main()
