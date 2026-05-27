#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: ./deploy_library_to_aws.sh <aws-bucket> [output-file-name]

Builds the library_for_spark package, builds the Docker artifact, and uploads it
to s3://<aws-bucket>/artifacts/pyspark/<output-file-name>.

Arguments:
  aws-bucket        Required. Destination S3 bucket name.
  output-file-name  Optional. Defaults to library_for_spark-0.1.0.tar.gz.
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage >&2
    exit 1
fi

aws_bucket="$1"
output_file_name="${2:-library_for_spark-0.1.0.tar.gz}"

uv build -o . --package library_for_spark

docker build --build-arg "OUTPUT_FILE_NAME=${output_file_name}" --output . .

aws s3 cp "${output_file_name}" "s3://${aws_bucket}/artifacts/pyspark/${output_file_name}"