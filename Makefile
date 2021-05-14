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
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME
	terraform \
		-chdir=$(CLUSTER_PROD) \
		init \
		-backend-config=bucket=$(BOOTSTRAP_BUCKET_NAME) \
		-backend-config=region=$(BOOTSTRAP_AWS_REGION) \
		-backend-config=dynamodb_table=$(BOOTSTRAP_DYNAMO_TABLE_NAME) \
		-backend=true

terraform-plan: terraform-init
	terraform -chdir=$(CLUSTER_PROD) plan -out "$$( pwd )/build/tfplan"
	terraform -chdir=$(CLUSTER_PROD) show -json "$$( pwd )/build/tfplan" > build/tfplan.json

deploy-cluster: terraform-plan snyk-test-plan
	rm build/tfplan.json
	terraform \
		-chdir=$(CLUSTER_PROD) \
		apply \
		-input=false \
		-auto-approve \
		"$$( pwd )/build/tfplan"
	rm build/tfplan

deploy-sock-shop:
	kubectl \
		--kubeconfig=secrets/config-prod.yml \
		apply \
		--filename deployments/sock-shop/manifest.yml
	
	kubectl \
		--kubeconfig=secrets/config-prod.yml \
		wait \
		--namespace sock-shop \
		--all=true \
		--for condition=ready \
		--timeout=600s \
		pod

# ===== Destroy ===============================================================

delete-sock-shop:
	kubectl \
		--kubeconfig=secrets/config-prod.yml \
		delete \
		--filename deployments/sock-shop/manifest.yml \
		--ignore-not-found=true \
		--wait=true

destroy-cluster:
	terraform -chdir=$(CLUSTER_PROD) destroy -input=false -auto-approve

# ===== Tests & Checks ========================================================

test: \
	terraform-validate \
	terraform-lint \
	terraform-fmt-check \
	snyk-test-terraform \
	snyk-test-deployments

terraform-validate:
	terraform -chdir=$(CLUSTER_PROD) validate

terraform-lint:
	tflint $(CLUSTER_PROD)

terraform-fmt-check:
	@if ! terraform -chdir=$(CLUSTER_PROD) fmt -check -diff; then \
		$(call print_fail,Run `terraform fmt $(CLUSTER_PROD)` to fix format errors); \
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

# ===== Jenkins ===============================================================

jenkins-%-deploy-pipeline: \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME \
	guard-SLACK_CHANNEL
	@sed \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		-e 's/REPLACE_ME_SLACK_CHANNEL/$(SLACK_CHANNEL)/' \
		pipelines/deploy.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Deploy (prod)'
	@$(call print_success,OK)

jenkins-%-destroy-pipeline: \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME \
	guard-SLACK_CHANNEL
	@sed \
		-e 's/REPLACE_ME_SLACK_CHANNEL/$(SLACK_CHANNEL)/' \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		pipelines/destroy.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Destroy (prod)'
	@$(call print_success,OK)

# ===== Miscellaneous =========================================================

COLOUR_GREEN=\033[0;32m
COLOUR_RED=\033[;31m
COLOUR_NONE=\033[0m

CLUSTER_PROD=terraform/deployments/cluster-prod

GITHUB_ORG ?= EngineerBetter
GITHUB_REPOSITORY ?= iac-example
REPOSITORY_URL=git@github.com:$(GITHUB_ORG)/$(GITHUB_REPOSITORY).git

configure-pre-commit-hook:
	@echo \
		"make terraform-validate; make terraform-lint; make terraform-fmt-check" \
		> .git/hooks/pre-commit
	@chmod +rx .git/hooks/pre-commit
	@$(call print_success,Configured pre-commit hook)

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
