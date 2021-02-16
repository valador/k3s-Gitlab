THIS_FILE := $(lastword $(MAKEFILE_LIST))

SHELL := /bin/bash

.PHONY: help
help:
	make -pRrq -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
# Set up docker-registry
.PHONY: prepear-init prepear-delete prepear-cert-manager
prepear-cert-manager:
	sudo kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.2.0/cert-manager.yaml
prepear-init:
	sudo kubectl apply -f ./k8s/0000-global/003-issuer.SELF.yml
	sudo kubectl apply -f ./k8s/0000-global/005-clusterissuer.SELF.yml
	sudo kubectl apply -f ./k8s/1000-gitlab/00-namespace.yml
	sudo kubectl apply -f ./k8s/1000-gitlab/05-certs.SELF.yml
	sudo kubectl apply -f ./k8s/utils/gitlab-admin-service-account.yaml
prepear-delete:
	sudo kubectl delete -f ./k8s/0000-global/003-issuer.SELF.yml
	sudo kubectl delete -f ./k8s/0000-global/005-clusterissuer.SELF.yml
	sudo kubectl delete -f ./k8s/1000-gitlab/05-certs.SELF.yml
	sudo kubectl delete -f ./k8s/utils/gitlab-admin-service-account.yaml
	sudo kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.2.0/cert-manager.yaml
	sudo kubectl delete -f ./k8s/1000-gitlab/00-namespace.yml
# base gitlab installation
.PHONY: gitlab-up gitlab-down
gitlab-up:
	sudo kubectl apply -f ./k8s/1000-gitlab/41-postgres.yaml
	sudo kubectl apply -f ./k8s/1000-gitlab/42-redis.yml
	sudo kubectl apply -f ./k8s/1000-gitlab/44-docker-registry.yaml
	sudo kubectl apply -f ./k8s/1000-gitlab/40-deployment.yml
	sudo kubectl apply -f ./k8s/1000-gitlab/50-ingress.yml
gitlab-down:
	sudo kubectl delete -f ./k8s/1000-gitlab/50-ingress.yml
	sudo kubectl delete -f ./k8s/1000-gitlab/44-docker-registry.yaml
	sudo kubectl delete -f ./k8s/1000-gitlab/40-deployment.yml
	sudo kubectl delete -f ./k8s/1000-gitlab/41-postgres.yaml
	sudo kubectl delete -f ./k8s/1000-gitlab/42-redis.yml
.PHONY: gitlab-runner-up gitlab-runner-down
gitlab-runner-up:
	sudo kubectl apply -f ./k8s/1000-gitlab/43-gitlab-runner.yml
gitlab-runner-down:
	sudo kubectl delete -f ./k8s/1000-gitlab/43-gitlab-runner.yml
.PHONY: gitlab-purge
gitlab-purge:
	sudo kubectl delete -n gitlab persistentvolumeclaim postgresql-postgresql-0
	sudo kubectl delete -n gitlab persistentvolumeclaim data-docker-registry-0
	sudo rm -rf /srv/gitlab
	sudo rm -rf /srv/gitlab-redis
# for ./secrets dir
.PHONY: cluster-secrets
cluster-secrets:
	sudo ./get-certificate-token.sh
.PHONY: get-all
get-all:
	sudo kubectl get all --all-namespaces