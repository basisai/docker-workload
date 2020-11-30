# docker-workload
The [workload-standard](https://hub.docker.com/r/basisai/workload-standard) docker image is optimised for running machine learning workloads on Kubernetes. It comes with the following packages pre-installed.
- Apache Spark 3.0
- PySpark 3.0
- Hadoop GCS Connector
- Hadoop S3 Connector

## Training on Bedrock

See [churn_prediction](https://github.com/basisai/churn_prediction) for a complete example.

To train a model using Spark on Bedrock, you will need to create a `bedrock.hcl` file with the following configuration.

```hcl
// Refer to https://docs.basis-ai.com/getting-started/writing-files/bedrock.hcl for more details.
version = "1.0"

train {
    step train {
        image = "basisai/workload-standard"
        install = [
            "pip install -r requirements.txt",
        ]
        script = [
            {spark-submit {
                script = "train.py"
                // to be passed in as --conf key=value
                conf {
                    spark.kubernetes.container.image = "basisai/workload-standard"
                    spark.kubernetes.pyspark.pythonVersion = "3"
                    spark.driver.memory = "4g"
                    spark.driver.cores = "2"
                    spark.executor.instances = "2"
                    spark.executor.memory = "4g"
                    spark.executor.cores = "2"
                    spark.memory.fraction = "0.5"
                    spark.sql.parquet.compression.codec = "gzip"
                    spark.hadoop.fs.AbstractFileSystem.gs.impl = "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS"
                    spark.hadoop.google.cloud.auth.service.account.enable = "true"
                }
                // to be passed in as --key=value
                settings {
                    py-files = "my_zip_files.zip"
                    // If you want to load data from BigQuery
                    jars = "gs://spark-lib/bigquery/spark-bigquery-latest.jar"
                }
            }}
        ]

        resources {
            cpu = "0.5"
            memory = "1G"
        }
    }
}
```

The `step` stanza specifies a single training step to be run. Multiple steps are allowed but they must have unique names. Additionally, you may pass in environment variables and secrets to all steps in the `train` stanza. Refer to [our documentation](https://docs.basis-ai.com/guides/writing-files/bedrock.hcl#train-stanza) for a complete list of supported parameters.

## How to Contribute

The main [Dockerfile](Dockerfile) downloads a pre-built Spark binary and unzips to `/opt/spark`. To upgrade to a new version, simply bump the `SPARK_VERSION` and `HADOOP_VERSION` environment variables to match the list of [pre-built packages](https://spark.apache.org/downloads.html) currently distributed by Apache.

Additional dependencies are specified in `pom.xml` so that we can use maven to help resolve transitive dependencies. This includes various connectors for distributed filesystems such as hadoop-gcs and hadoop-s3.
