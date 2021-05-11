COLOUR_GREEN=\033[0;32m
COLOUR_NONE=\033[0m

CLUSTER_PROD=terraform/deployments/cluster-prod

deploy-cluster:
	@terraform \
		-chdir=$(CLUSTER_PROD) \
		init \
		-input=false

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
