COLOUR_GREEN=\033[0;32m
COLOUR_RED=\033[;31m
COLOUR_NONE=\033[0m

CLUSTER_PROD=terraform/deployments/cluster-prod

# ===== Deployment ============================================================

terraform-bootstrap: \
	guard-BOOTSTRAP_AWS_REGION \
	guard-BOOTSTRAP_BUCKET_NAME \
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME
	./bootstrap/bootstrap.bash

terraform-init: \
	guard-BOOTSTRAP_AWS_REGION \
	guard-BOOTSTRAP_BUCKET_NAME \
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME
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

deploy-sock-shop:
	@kubectl \
		--kubeconfig=secrets/config-prod.yml \
		apply \
		--filename deployments/sock-shop/manifest.yml

# ===== Tests & Checks ========================================================

test: \
	terraform-validate \
	snyk-test-terraform \
	snyk-test-deployments

terraform-validate:
	terraform \
		-chdir=$(CLUSTER_PROD) \
		validate

snyk-test-terraform: guard-SNYK_TOKEN
	snyk iac test terraform/

snyk-test-deployments: guard-SNYK_TOKEN
	snyk iac test deployments/

# ===== Miscellaneous =========================================================

fetch-cluster-config:
	@terraform \
		-chdir=$(CLUSTER_PROD) \
		output \
		-raw \
		kubeconfig \
		> ./secrets/config-prod.yml
	@$(call print_success,Config written to secrets/config-prod.yml)

guard-%:
	@if [ "${${*}}" = "" ]; then \
		$(call print_fail,Environment variable $* must be set) \
		&& exit 1; \
	fi

define print_success
	printf '$(COLOUR_GREEN)$1$(COLOUR_NONE)\n'
endef

define print_fail
	printf '$(COLOUR_RED)$1$(COLOUR_NONE)\n'
endef
