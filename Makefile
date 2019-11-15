# These are the usual GKE variables.
PROJECT       ?= prow-clarketm
ZONE          ?= us-west1-a
CLUSTER       ?= prow

export KUBECONFIG

.PHONY: save-kubeconfig
save-kubeconfig:
ifndef save
	$(eval KUBECONFIG=$(shell mktemp))
endif

.PHONY: get-cluster-credentials
get-cluster-credentials: save-kubeconfig
	CLOUDSDK_CONTAINER_USE_CLIENT_CERTIFICATE=True gcloud container clusters get-credentials "$(CLUSTER)" --project="$(PROJECT)" --zone="$(ZONE)"

.PHONY: update-deployment
update-deployment: get-cluster-credentials
	kubectl apply -f ./starter_after.yaml,./nginx.yaml,./deck_private.yaml,./cherrypicker.yaml

.PHONY: replace-deployment
replace-deployment: get-cluster-credentials
	kubectl replace -f ./starter_after.yaml,./nginx.yaml,./deck_private.yaml,./cherrypicker.yaml

.PHONY: delete-deployment
delete-deployment: get-cluster-credentials
	kubectl delete -f ./starter_after.yaml,./nginx.yaml,./deck_private.yaml,./cherrypicker.yaml

.PHONY: update-plugins
update-plugins: get-cluster-credentials
	kubectl create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl apply -f -

.PHONY: update-config
update-config: get-cluster-credentials
	kubectl create configmap config --from-file=config.yaml=config.yaml --dry-run -o yaml | kubectl apply -f -

.PHONY: create-deck-oauth-proxy-secret
create-deck-oauth-proxy-secret: get-cluster-credentials
	kubectl create secret generic deck-oauth-proxy --from-file=clientID=./deck-oauth-proxy.clientID.yaml --from-file=clientSecret=./deck-oauth-proxy.clientSecret.yaml --from-file=cookieSecret=./deck-oauth-proxy.cookieSecret.yaml
	