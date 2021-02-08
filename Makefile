THIS_FILE := $(lastword $(MAKEFILE_LIST))

SHELL := /bin/bash

.PHONY: help
help:
	make -pRrq -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
# Set up docker-registry
.PHONY: reg-create reg-delete
reg-create:
        sudo kubectl apply -f ./registry/docker-registry.yaml
reg-delete:
        sudo kubectl delete -f ./registry/docker-registry.yaml

# base gitlab installation
.PHONY: gitlab-up gitlab-down
gitlab-up:
	sudo kubectl create -f ./k8s/1000-gitlab/00-namespace.yml
	sudo kubectl apply -f ./k8s/1000-gitlab/05-certs.yml.SELF
	sudo kubectl create -f ./k8s/1000-gitlab/10-services.yml
	sudo kubectl create -f ./k8s/1000-gitlab/20-configmap.yml
	sudo kubectl create -f ./k8s/1000-gitlab/40-deployment.yml
	sudo kubectl create -f ./k8s/1000-gitlab/50-ingress.yml.SELF
gitlab-down:
	sudo kubectl delete -f ./k8s/1000-gitlab/50-ingress.yml.SELF
	sudo kubectl delete -f ./k8s/1000-gitlab/40-deployment.yml
	sudo kubectl delete -f ./k8s/1000-gitlab/20-configmap.yml
	sudo kubectl delete -f ./k8s/1000-gitlab/10-services.yml
	sudo kubectl delete -f ./k8s/1000-gitlab/05-certs.yml.SELF
	sudo kubectl delete -f ./k8s/1000-gitlab/00-namespace.yml
	sudo rm -rf /srv

.PHONY: cluster-admin-create cluster-admin-delete
cluster-admin-create:
	sudo kubectl apply -f ./k8s/utils/gitlab-admin-service-account.yaml
cluster-admin-delete:
	sudo kubectl delete -f ./k8s/utils/gitlab-admin-service-account.yaml
# for ./secrets dir
.PHONY: cluster-secrets
cluster-secrets:
	sudo ./get-token.sh