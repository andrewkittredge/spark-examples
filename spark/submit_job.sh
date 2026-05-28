#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: ./start_serverless_demo_job.sh --application-id <id> --execution-role-arn <arn> --aws-bucket <bucket> [options]

Uploads serverless_demo_job.py to S3 and submits it to EMR Serverless with the
Spark configuration values from serverless_demo.ipynb.

Required arguments:
  --application-id <id>          EMR Serverless application ID.
  --execution-role-arn <arn>     IAM role ARN for the job run.
  --aws-bucket <bucket>          S3 bucket containing the library archive and job file.

Options:
  --job-name <name>              Job run name. Defaults to serverless-demo.
  --job-s3-key <key>             S3 key for serverless_demo_job.py. Defaults to artifacts/pyspark/serverless_demo_job.py.
  --library-archive-file <file>  Library archive file name. Defaults to library_for_spark-0.1.0.tar.gz.
  --log-uri <s3-uri>             Optional S3 URI for EMR Serverless logs.
  --profile <profile>            Optional AWS CLI profile.
  --region <region>              Optional AWS region.
  --client-token <token>         Optional idempotency token.
  --skip-upload                  Do not upload serverless_demo_job.py before submitting.
  -h, --help                     Show this help.

Example:
  ./start_serverless_demo_job.sh \
    --application-id 00f0example1ab2cd3 \
    --execution-role-arn arn:aws:iam::123456789012:role/EMRServerlessJobRole \
    --aws-bucket my-spark-artifacts \
    --region us-east-1 \
    --log-uri s3://my-spark-artifacts/logs/emr-serverless/
USAGE
}

application_id=""
execution_role_arn=""
aws_bucket=""
job_name="serverless-demo"
job_s3_key="artifacts/pyspark/serverless_demo_job.py"
library_archive_file_name="library_for_spark-0.1.0.tar.gz"
log_uri=""
aws_profile=""
aws_region=""
client_token=""
skip_upload=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --application-id)
            application_id="$2"
            shift 2
            ;;
        --execution-role-arn)
            execution_role_arn="$2"
            shift 2
            ;;
        --aws-bucket)
            aws_bucket="$2"
            shift 2
            ;;
        --job-name)
            job_name="$2"
            shift 2
            ;;
        --job-s3-key)
            job_s3_key="$2"
            shift 2
            ;;
        --library-archive-file)
            library_archive_file_name="$2"
            shift 2
            ;;
        --log-uri)
            log_uri="$2"
            shift 2
            ;;
        --profile)
            aws_profile="$2"
            shift 2
            ;;
        --region)
            aws_region="$2"
            shift 2
            ;;
        --client-token)
            client_token="$2"
            shift 2
            ;;
        --skip-upload)
            skip_upload=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$application_id" || -z "$execution_role_arn" || -z "$aws_bucket" ]]; then
    usage >&2
    exit 1
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
job_file="${script_directory}/serverless_demo_job.py"

if [[ ! -f "$job_file" ]]; then
    echo "Could not find job file at ${job_file}" >&2
    exit 1
fi

job_s3_uri="s3://${aws_bucket}/${job_s3_key}"
library_archive_s3_uri="s3://${aws_bucket}/artifacts/pyspark/${library_archive_file_name}#environment"

aws_args=()
if [[ -n "$aws_profile" ]]; then
    aws_args+=(--profile "$aws_profile")
fi
if [[ -n "$aws_region" ]]; then
    aws_args+=(--region "$aws_region")
fi

if [[ "$skip_upload" == false ]]; then
    aws "${aws_args[@]}" s3 cp "$job_file" "$job_s3_uri"
fi

# These Spark configuration values mirror the %%configure block in serverless_demo.ipynb.
spark_submit_parameters="--conf spark.archives=${library_archive_s3_uri} --conf spark.emr-serverless.driverEnv.PYSPARK_DRIVER_PYTHON=./environment/bin/python --conf spark.emr-serverless.driverEnv.PYSPARK_PYTHON=./environment/bin/python --conf spark.executorEnv.PYSPARK_PYTHON=./environment/bin/python"

job_driver="$(JOB_S3_URI="$job_s3_uri" SPARK_SUBMIT_PARAMETERS="$spark_submit_parameters" \
    python -c 'import json, os; print(json.dumps({"sparkSubmit": {"entryPoint": os.environ["JOB_S3_URI"], "sparkSubmitParameters": os.environ["SPARK_SUBMIT_PARAMETERS"]}}, separators=(",", ":")))')"

start_job_run_args=(
    emr-serverless start-job-run
    --application-id "$application_id"
    --execution-role-arn "$execution_role_arn"
    --name "$job_name"
    --job-driver "$job_driver"
)

if [[ -n "$log_uri" ]]; then
    configuration_overrides="$(LOG_URI="$log_uri" \
        python -c 'import json, os; print(json.dumps({"monitoringConfiguration": {"s3MonitoringConfiguration": {"logUri": os.environ["LOG_URI"]}}}, separators=(",", ":")))')"

    start_job_run_args+=(--configuration-overrides "$configuration_overrides")
fi

if [[ -n "$client_token" ]]; then
    start_job_run_args+=(--client-token "$client_token")
fi

aws "${aws_args[@]}" "${start_job_run_args[@]}"