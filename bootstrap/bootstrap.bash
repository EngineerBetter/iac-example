#!/usr/bin/env bash
set -eu

function create_bucket() {
  local region="$1"
  local name="$2"

  if aws s3 ls "s3://$name" 2>&1 | grep -q 'NoSuchBucket'; then
    echo 'Creating S3 bucket...'
    aws s3api create-bucket \
      --bucket "$name" \
      --create-bucket-configuration="{\"LocationConstraint\": \"${region}\"}" \
      1>/dev/null
    aws s3api put-bucket-versioning \
      --bucket "$name" \
      --versioning-configuration Status=Enabled \
      1>/dev/null
  fi
}

function create_table() {
  local region="$1"
  local name="$2"

  if aws dynamodb describe-table --region "$region" --table-name "$name" 2>&1 | grep -q 'not found'; then
    echo 'Creating DynamoDB table...'
    aws dynamodb create-table \
      --region "$region" \
      --table-name "$name" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
      1>/dev/null
  fi
}

create_bucket "$BOOTSTRAP_AWS_REGION" "$BOOTSTRAP_BUCKET_NAME"
create_table "$BOOTSTRAP_AWS_REGION" "$BOOTSTRAP_DYNAMO_TABLE_NAME"