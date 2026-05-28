# Build and deploy a Python package as a dependency for PySpark on AWS EMR Serverless

https://spark.apache.org/docs/latest/api/python/tutorial/python_packaging.html

## Use the package in a Spark Connect notebook in a Serverless Workspace


1. Run `deploy_library_to_aws.ps1` or `deploy_library_to_aws.sh` in the `spark` directory.

2. Copy  `serverless_demo.ipynb` to the EMR Studio Workspace.  Replace the `{S3_bucket}` in the conf json with your S3 bucket.

## Use the package with in a submitted job

Run `start_serverless_demo_job.ps1` or `start_serverless_demo_job.sh` in the `spark` directory. 