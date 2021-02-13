Разрешаем подключение к кластеру:
Admin > Settings > Network > expand "Outbound requests" > check:
* Allow requests to the local network from web hooks and services - иначе не работает добавление кластера по dns имени или ip (localhost все равно не принимает)
* Allow requests to the local network from system hooks

## Deploy a GitLab runner to Kubernetes

Return to this directory: `k3s-cluster/gitlab-integration` and:

- run `make cluster-admin-create` to create a GitLab account inside the cluster
- run `./get-certificate-token.sh` to generate the certificate and the token you will need to declare the cluster inside GitLab. The two files will be generated in the sub-directory `/secrets`
- run `./03-add-gitlab-host-to-cluster.sh` to add the GitLab entry to the Cluster's VM
- run `./04-patch-core-dns.sh` to "patch" again the configmap of CoreDNS (making GitLab reachable from the cluster)

Now, return to http://little-gitlab.test/, and in the admin section go to the Kubernetes section (`/admin/clusters`), click on **Add Kubernetes cluster**, choose **Add existing cluster** and fill the fields like that:

- **Kubernetes cluster name**: little-cluster (or what you want)
- **API URL**: https://dev-srv:6443 (you can find the appropriate value in the `k3s.yaml` file
- **CA Certificate**: use the content of `secrets/CA.txt`
- **Service Token**: use the content of `secrets/TOKEN.txt`

And then, click on **"Add Kubernetes cluster"**

On the next screen, 
- Click on **"Install"** at the **"Helm Tiller"** section (you can follow the progress from K9S console)
- Once, Helm Tiller installed, click on **"Install"** at the **"GitLab Runner"** section (you can follow the progress from K9S console)
- Once the installation of the runner is finished, you can check if the runner is correctly registered by reaching the runner's section of the administration console (/admin/runners).

Now, you're almost ready to deploy from Kubernetes from GitLab.

# Порядок запуска:
## 1:
```
sudo kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
```
## 2: 
```
sudo kubectl create -f ./k8s/1000-gitlab/00-namespace.yml
sudo kubectl apply -f ./k8s/1000-gitlab/05-certs.yml.SELF
```
## 3:
```bash
sudo kubectl apply -f ./k8s/0000-global/003-issuer.yml.SELF
sudo kubectl apply -f ./k8s/0000-global/005-clusterissuer.yml.SELF 
```
## 4:
```
sudo kubectl describe certificates gitlab-home -n gitlab
```
## 5:
ищем строчку:
```
Created new CertificateRequest resource "gitlab-home-s94nj"
```
gitlab-home-s94nj - используем дальше:
```
sudo kubectl describe certificaterequest gitlab-home-s94nj -n gitlab
```
выдает ошибку:
```
Normal  IssuerNotFound     82s (x5 over 82s)  cert-manager  Referenced "ClusterIssuer" not found: clusterissuer.cert-manager.io "selfsigned-issuer" not found
```
разобраться.
## 6:
sudo kubectl describe challenges gitlab-home-s94nj -n gitlab