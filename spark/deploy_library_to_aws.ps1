param(
    [Parameter(Mandatory = $true)]
    [string]$AwsBucket,

    [string]$OutputFileName = "library_for_spark-0.1.0.tar.gz"
)

uv build -o . --package library_for_spark

docker build --build-arg OUTPUT_FILE_NAME=$OutputFileName --output . .

aws s3 cp $OutputFileName "s3://$AwsBucket/artifacts/pyspark/$OutputFileName"