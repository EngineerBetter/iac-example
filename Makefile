# ===== Deployment ============================================================

terraform-bootstrap: \
	guard-BOOTSTRAP_AWS_REGION \
	guard-BOOTSTRAP_BUCKET_NAME \
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME
	@./bootstrap/bootstrap.bash
	@$(call print_success,OK)

terraform-init: \
	guard-BOOTSTRAP_AWS_REGION \
	guard-BOOTSTRAP_BUCKET_NAME \
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME \
	guard-TF_VAR_env_name
	terraform \
		-chdir=$(CLUSTER) \
		init \
		-backend=true \
		-reconfigure \
		-input=false \
		-backend-config=bucket=$(BOOTSTRAP_BUCKET_NAME) \
		-backend-config=region=$(BOOTSTRAP_AWS_REGION) \
		-backend-config=dynamodb_table=$(BOOTSTRAP_DYNAMO_TABLE_NAME) \
		-backend-config=key=$(TF_VAR_env_name)

terraform-plan: guard-TF_VAR_env_name terraform-init
	terraform -chdir=$(CLUSTER) plan -out "$$( pwd )/build/tfplan"
	terraform -chdir=$(CLUSTER) show -json "$$( pwd )/build/tfplan" > build/tfplan.json

deploy-cluster: guard-TF_VAR_env_name terraform-plan snyk-test-plan
	rm build/tfplan.json
	terraform \
		-chdir=$(CLUSTER) \
		apply \
		"$$( pwd )/build/tfplan"
	rm build/tfplan

deploy-sock-shop: guard-TF_VAR_env_name
	kubectl \
		--kubeconfig=secrets/config-$(TF_VAR_env_name).yml \
		apply \
		--filename deployments/sock-shop/manifest.yml
	
	kubectl \
		--kubeconfig=secrets/config-$(TF_VAR_env_name).yml \
		wait \
		--namespace sock-shop \
		--all=true \
		--for condition=ready \
		--timeout=600s \
		pod

# ===== Destroy ===============================================================

delete-sock-shop: guard-TF_VAR_env_name
	kubectl \
		--kubeconfig=secrets/config-$(TF_VAR_env_name).yml \
		delete \
		--filename deployments/sock-shop/manifest.yml \
		--ignore-not-found=true \
		--wait=true

destroy-cluster: guard-TF_VAR_env_name terraform-init
	terraform -chdir=$(CLUSTER) destroy

# ===== Tests & Checks ========================================================

test: \
	terraform-validate \
	terraform-lint \
	terraform-fmt-check \
	snyk-test-terraform \
	snyk-test-deployments

terraform-validate:
	terraform -chdir=$(CLUSTER) validate

terraform-lint:
	tflint $(CLUSTER)

terraform-fmt-check:
	@if ! terraform -chdir=$(CLUSTER) fmt -check -diff; then \
		$(call print_fail,Run `terraform fmt $(CLUSTER)` to fix format errors); \
	fi

snyk-test-terraform: guard-SNYK_TOKEN
	snyk iac test terraform/

snyk-test-deployments: guard-SNYK_TOKEN
ifdef IGNORE_SNYK_TEST_DEPLOYMENTS_FAILURE
	snyk iac test deployments/ || true
else
	snyk iac test deployments/
endif

snyk-test-plan: guard-SNYK_TOKEN
ifdef IGNORE_SNYK_TEST_PLAN_FAILURE
	snyk iac test --scan=planned-values build/tfplan.json || true
else
	snyk iac test --scan=planned-values build/tfplan.json
endif

integration-test: guard-TF_VAR_env_name
	cd tests/integration && \
	SOCK_SHOP_URL="$$( kubectl \
		--kubeconfig=../../secrets/config-$(TF_VAR_env_name).yml \
		-n sock-shop \
		get service/front-end \
		-o jsonpath="{.status.loadBalancer.ingress[0].hostname}" \
	)" $(GINKGO) --race --randomizeAllSpecs -r .

policy-test:
	conftest test -p tests/policies deployments/sock-shop/manifest.yml

# ===== Jenkins ===============================================================

jenkins-%-deploy-pipeline: \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME \
	guard-SLACK_CHANNEL \
	guard-TF_VAR_env_name
	@sed \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		-e 's/REPLACE_ME_SLACK_CHANNEL/$(SLACK_CHANNEL)/' \
		-e 's/REPLACE_ME_ENV_NAME/$(TF_VAR_env_name)/' \
		pipelines/deploy.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Deploy ($(TF_VAR_env_name))'
	@$(call print_success,OK)

jenkins-%-destroy-pipeline: \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME \
	guard-SLACK_CHANNEL \
	guard-TF_VAR_env_name
	@sed \
		-e 's/REPLACE_ME_SLACK_CHANNEL/$(SLACK_CHANNEL)/' \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		-e 's/REPLACE_ME_ENV_NAME/$(TF_VAR_env_name)/' \
		pipelines/destroy.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Destroy ($(TF_VAR_env_name))'
	@$(call print_success,OK)

# ===== Miscellaneous =========================================================

GINKGO := go run github.com/onsi/ginkgo/ginkgo

COLOUR_GREEN=\033[0;32m
COLOUR_RED=\033[;31m
COLOUR_NONE=\033[0m

CLUSTER=terraform/cluster

GITHUB_ORG ?= EngineerBetter
GITHUB_REPOSITORY ?= iac-example
REPOSITORY_URL=git@github.com:$(GITHUB_ORG)/$(GITHUB_REPOSITORY).git

configure-pre-commit-hook:
	@echo \
		"make terraform-validate; make terraform-lint; make terraform-fmt-check" \
		> .git/hooks/pre-commit
	@chmod +rx .git/hooks/pre-commit
	@$(call print_success,Configured pre-commit hook)

fetch-cluster-config: guard-TF_VAR_env_name terraform-init
	@terraform \
		-chdir=$(CLUSTER) \
		output \
		-raw \
		kubeconfig \
		> ./secrets/config-$(TF_VAR_env_name).yml
	@$(call print_success,Config written to secrets/config-$(TF_VAR_env_name).yml)

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
