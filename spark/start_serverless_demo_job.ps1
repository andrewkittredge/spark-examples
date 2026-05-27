param(
    [Parameter(Mandatory = $true)]
    [string]$ApplicationId,

    [Parameter(Mandatory = $true)]
    [string]$ExecutionRoleArn,

    [Parameter(Mandatory = $true)]
    [string]$AwsBucket,

    [string]$JobName = "serverless-demo",

    [string]$JobS3Key = "artifacts/pyspark/serverless_demo_job.py",

    [string]$LibraryArchiveFileName = "library_for_spark-0.1.0.tar.gz",

    [string]$LogUri,

    [string]$AwsProfile,

    [string]$AwsRegion,

    [string]$ClientToken,

    [switch]$SkipUpload
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobFile = Join-Path $scriptDirectory "serverless_demo_job.py"

if (-not (Test-Path $jobFile)) {
    throw "Could not find job file at $jobFile"
}

$jobS3Uri = "s3://$AwsBucket/$JobS3Key"
$libraryArchiveS3Uri = "s3://$AwsBucket/artifacts/pyspark/$LibraryArchiveFileName#environment"

$awsArgs = @()
if ($AwsProfile) {
    $awsArgs += @("--profile", $AwsProfile)
}
if ($AwsRegion) {
    $awsArgs += @("--region", $AwsRegion)
}

if (-not $SkipUpload) {
    aws @awsArgs s3 cp $jobFile $jobS3Uri
}

# These Spark configuration values mirror the %%configure block in serverless_demo.ipynb.
$sparkSubmitParameters = @(
    "--conf", "spark.archives=$libraryArchiveS3Uri",
    "--conf", "spark.emr-serverless.driverEnv.PYSPARK_DRIVER_PYTHON=./environment/bin/python",
    "--conf", "spark.emr-serverless.driverEnv.PYSPARK_PYTHON=./environment/bin/python",
    "--conf", "spark.executorEnv.PYSPARK_PYTHON=./environment/bin/python"
) -join " "

$jobDriver = @{
    sparkSubmit = @{
        entryPoint            = $jobS3Uri
        sparkSubmitParameters = $sparkSubmitParameters
    }
} | ConvertTo-Json -Depth 5 -Compress

$startJobRunArgs = @(
    "emr-serverless", "start-job-run",
    "--application-id", $ApplicationId,
    "--execution-role-arn", $ExecutionRoleArn,
    "--name", $JobName,
    "--job-driver", $jobDriver
)

if ($LogUri) {
    $configurationOverrides = @{
        monitoringConfiguration = @{
            s3MonitoringConfiguration = @{
                logUri = $LogUri
            }
        }
    } | ConvertTo-Json -Depth 5 -Compress

    $startJobRunArgs += @("--configuration-overrides", $configurationOverrides)
}

if ($ClientToken) {
    $startJobRunArgs += @("--client-token", $ClientToken)
}

aws @awsArgs @startJobRunArgs