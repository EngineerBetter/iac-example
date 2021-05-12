COLOUR_GREEN=\033[0;32m
COLOUR_RED=\033[;31m
COLOUR_NONE=\033[0m

CLUSTER_PROD=terraform/deployments/cluster-prod

terraform-init: guard-BOOTSTRAP_AWS_REGION guard-BOOTSTRAP_BUCKET_NAME guard-BOOTSTRAP_DYNAMO_TABLE_NAME
	@terraform \
		-chdir=$(CLUSTER_PROD) \
		init \
		-backend-config=bucket=$(BOOTSTRAP_BUCKET_NAME) \
		-backend-config=region=$(BOOTSTRAP_AWS_REGION) \
		-backend-config=dynamodb_table=$(BOOTSTRAP_DYNAMO_TABLE_NAME) \
		-backend=true

deploy-cluster: terraform-init
	@terraform \
		-chdir=$(CLUSTER_PROD) \
		apply \
		-input=false \
		-auto-approve

fetch-cluster-config:
	@terraform \
		-chdir=$(CLUSTER_PROD) \
		output \
		-raw \
		kubeconfig \
		> ./secrets/config-prod.yml
	@printf '$(COLOUR_GREEN)Config written to secrets/config-prod.yml$(COLOUR_NONE)\n'

deploy-sock-shop:
	@kubectl \
		--kubeconfig=secrets/config-prod.yml \
		apply \
		--filename deployments/sock-shop/manifest.yml

terraform-bootstrap:
	./bootstrap/bootstrap.bash

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		printf '$(COLOUR_RED)Environment variable $* must be set$(COLOUR_NONE)\n' \
		&& exit 1; \
	fi
