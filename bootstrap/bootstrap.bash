#!/usr/bin/env bash
set -euo pipefail

function create_bucket() {
  local region="$1"
  local name="$2"

  aws s3api create-bucket \
      --bucket "$name" \
      --create-bucket-configuration="{\"LocationConstraint\": \"${region}\"}"
  aws s3api put-bucket-versioning \
      --bucket "$name" \
      --versioning-configuration Status=Enabled
}

function create_table() {
  local region="$1"
  local name="$2"

  aws dynamodb create-table \
    --region "$region" \
    --table-name "$name" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
}

create_bucket "$BOOTSTRAP_AWS_REGION" "$BOOTSTRAP_BUCKET_NAME"
create_table "$BOOTSTRAP_AWS_REGION" "$BOOTSTRAP_DYNAMO_TABLE_NAME"