# docker-workload
The [workload-standard](https://hub.docker.com/r/basisai/workload-standard) docker image is optimised for running machine learning workloads on Kubernetes. It comes with the following packages pre-installed.
- Apache Spark 3.0
- PySpark 3.0
- Hadoop GCS Connector
- Hadoop S3 Connector

## Training on Bedrock

See [churn_prediction](https://github.com/basisai/churn_prediction) for a complete example.

To train a model on Bedrock, you will need to create a `bedrock.hcl` file with the following configuration.

```hcl
// Refer to https://docs.basis-ai.com/getting-started/writing-files/bedrock.hcl for more details.
version = "1.0"

train {
    step train {
        image = "basisai/workload-standard:v0.2.2"
        install = [
            "pip install -r requirements.txt",
        ]
        script = [
            {sh = [
                "python3 train.py"
            ]}
        ]

        resources {
            cpu = "0.5"
            memory = "1G"
            // gpu = "1"  // Uncomment to enable GPU support. Only integer values are allowed.
        }
    }
}
```

The `step` stanza specifies a single training step to be run. It comprises of the following fields:

- [required] **image**: the base Docker image that the script will run in
- [optional] install: the command to install any other packages not covered in the image
- [required] **script**: the command that calls the script
- [optional] resources: the computing resources to be allocated to this run step
- [optional] depends_on: a list of names of steps that this run step depends on

Multiple steps are allowed but they must have unique names.

Additionally, you may pass in variables and secrets to all steps in the `train` stanza.

- [optional] parameters: environment variables used by the script. They can be overwritten when you create a run.
- [optional] secrets: the names of the secrets necessary to run the script successfully

## How to Contribute

The main [Dockerfile](Dockerfile) downloads a pre-built Spark binary and unzips to `/opt/spark`. To upgrade to a new version, simply bump the `SPARK_VERSION` and `HADOOP_VERSION` environment variables to match the list of [pre-built packages](https://spark.apache.org/downloads.html) currently distributed by Apache.

Additional dependencies are specified in `pom.xml` so that we can use maven to help resolve transitive dependencies. This includes various connectors for distributed filesystems such as hadoop-gcs and hadoop-s3.
