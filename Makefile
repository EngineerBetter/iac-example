# ===== Deployment ============================================================

terraform-bootstrap: \
	guard-BOOTSTRAP_AWS_REGION \
	guard-BOOTSTRAP_BUCKET_NAME \
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME
	@./bootstrap/bootstrap.bash
	@$(call print_success,OK)

terraform-init: \
	load-env \
	guard-BOOTSTRAP_AWS_REGION \
	guard-BOOTSTRAP_BUCKET_NAME \
	guard-BOOTSTRAP_DYNAMO_TABLE_NAME
	terraform \
		-chdir=$(CLUSTER) \
		init \
		-backend=true \
		-reconfigure \
		-input=false \
		-backend-config=bucket=$(BOOTSTRAP_BUCKET_NAME) \
		-backend-config=region=$(BOOTSTRAP_AWS_REGION) \
		-backend-config=dynamodb_table=$(BOOTSTRAP_DYNAMO_TABLE_NAME) \
		-backend-config=key=$(ENV_NAME)

terraform-plan: load-env terraform-init
	terraform -chdir=$(CLUSTER) plan -var="env_name=$(ENV_NAME)" -out "$$( pwd )/build/tfplan"
	terraform -chdir=$(CLUSTER) show -json "$$( pwd )/build/tfplan" > build/tfplan.json

deploy-cluster: load-env terraform-plan snyk-test-plan
	rm build/tfplan.json
	terraform \
		-chdir=$(CLUSTER) \
		apply \
		"$$( pwd )/build/tfplan"
	rm build/tfplan

deploy-sock-shop: load-env
	kubectl \
		--kubeconfig=secrets/config-$(ENV_NAME).yml \
		apply \
		--filename deployments/sock-shop/manifest.yml

	kubectl \
		--kubeconfig=secrets/config-$(ENV_NAME).yml \
		wait \
		--namespace sock-shop \
		--all=true \
		--for condition=ready \
		--timeout=600s \
		pod

# ===== Destroy ===============================================================

delete-sock-shop: load-env
	kubectl \
		--kubeconfig=secrets/config-$(ENV_NAME).yml \
		delete \
		--filename deployments/sock-shop/manifest.yml \
		--ignore-not-found=true \
		--wait=true

destroy-cluster: load-env terraform-init
	terraform -chdir=$(CLUSTER) destroy -var="env_name=$(ENV_NAME)"

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

integration-test: load-env
	cd tests/integration && \
	SOCK_SHOP_URL="$$( kubectl \
		--kubeconfig=../../secrets/config-$(ENV_NAME).yml \
		-n sock-shop \
		get service/front-end \
		-o jsonpath="{.status.loadBalancer.ingress[0].hostname}" \
	)" $(GINKGO) --race --randomizeAllSpecs -r .

policy-test:
	conftest test -p tests/policies deployments/sock-shop/manifest.yml

# ===== Jenkins ===============================================================

jenkins-update-pipelines: \
	jenkins-update-deploy-pipeline \
	jenkins-update-destroy-pipeline \
	jenkins-update-promote-pipeline

jenkins-create-pipelines: \
	jenkins-create-deploy-pipeline \
	jenkins-create-destroy-pipeline \
	jenkins-create-promote-pipeline

jenkins-%-deploy-pipeline: \
	load-env \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME \
	guard-SLACK_CHANNEL
	@echo -n Setting deploy pipeline...
	@sed \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		-e 's/REPLACE_ME_SLACK_CHANNEL/$(SLACK_CHANNEL)/' \
		-e 's/REPLACE_ME_PROMOTES_FROM/$(PROMOTES_FROM)/' \
		-e 's/REPLACE_ME_ENV_NAME/$(ENV_NAME)/' \
		-e 's/REPLACE_ME_PROMOTES_TO/$(PROMOTES_TO)/' \
		pipelines/deploy.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Deploy ($(ENV_NAME))'
	@$(call print_success, OK!)

jenkins-%-destroy-pipeline: \
	load-env \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME \
	guard-SLACK_CHANNEL
	@echo -n Setting destroy pipeline...
	@sed \
		-e 's/REPLACE_ME_SLACK_CHANNEL/$(SLACK_CHANNEL)/' \
		-e 's/REPLACE_ME_ENV_NAME/$(ENV_NAME)/' \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		-e 's/REPLACE_ME_PROMOTES_TO/$(PROMOTES_TO)/' \
		pipelines/destroy.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Destroy ($(ENV_NAME))'
	@$(call print_success, OK!)

jenkins-%-promote-pipeline: \
	guard-JENKINS_CLI \
	guard-JENKINS_URL \
	guard-JENKINS_PASSWORD \
	guard-JENKINS_USERNAME
	@echo -n Setting promote pipeline...
	@sed \
		-e 's#REPLACE_ME_REPOSITORY_URL#$(REPOSITORY_URL)#' \
		pipelines/push-git-branch.xml \
		| java \
			-jar $(JENKINS_CLI) \
			-s $(JENKINS_URL) \
			-auth "$(JENKINS_USERNAME):$${JENKINS_PASSWORD}" \
			$*-job 'Push Git Branch'
	@$(call print_success, OK!)

# ===== Miscellaneous =========================================================

GINKGO := go run github.com/onsi/ginkgo/ginkgo

COLOUR_GREEN=\033[0;32m
COLOUR_RED=\033[;31m
COLOUR_NONE=\033[0m

CLUSTER=terraform/cluster

GITHUB_ORG ?= EngineerBetter
GITHUB_REPOSITORY ?= iac-example
REPOSITORY_URL=git@github.com:$(GITHUB_ORG)/$(GITHUB_REPOSITORY).git

load-env:
	@if [ -z "$$(yq eval '.[] | select(.name == "$(ENV_NAME)") | .name' environments.yml)" ]; then \
		$(call print_fail,No such environment) \
		&& exit 1; \
	fi

	$(eval PROMOTES_FROM := $(shell \
		yq \
			eval \
			'.[] | select(.name == "$(ENV_NAME)") | .promotes_from // "main"' \
			environments.yml \
	))

	$(eval PROMOTES_TO := $(shell \
		yq \
			eval \
			'.[] | select(.name == "$(ENV_NAME)") | .promotes_to' \
			environments.yml \
	))

	@if [ "$(PROMOTES_TO)" = "null" ]; then \
		$(call print_fail,Required field "promotes_to" not defined for $(ENV_NAME)) \
		&& exit 1; \
	fi

configure-pre-commit-hook:
	@echo \
		"make terraform-validate; make terraform-lint; make terraform-fmt-check" \
		> .git/hooks/pre-commit
	@chmod +rx .git/hooks/pre-commit
	@$(call print_success,Configured pre-commit hook)

fetch-cluster-config: load-env terraform-init
	@terraform \
		-chdir=$(CLUSTER) \
		output \
		-raw \
		kubeconfig \
		> ./secrets/config-$(ENV_NAME).yml
	@$(call print_success,Config written to secrets/config-$(ENV_NAME).yml)

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
