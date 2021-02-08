#!/bin/bash
KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      
grep 'certificate' $KUBECONFIG | awk -F ': ' '{print $2}' | base64 -d > ./secrets/CA.txt

SECRET=$(kubectl -n kube-system get secret | grep gitlab | awk '{print $1}')

kubectl -n kube-system get secret $SECRET -o jsonpath='{.data.token}' | base64 -d > ./secrets/TOKEN.txt

#kubectl config view --raw \
#-o=jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
#| base64 --decode > CA.txt
