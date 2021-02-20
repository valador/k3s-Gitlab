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
```bash
# Устанавливаем менеджер сертификатов в кластер
make prepear-cert-manager-up
```
## 2: 
```bash
# создаем область имен gitlab
make prepear-namespace-up
```
## 3: 
```bash
# Заказываем сертификаты, создаем сертификаты, 
# создаем аккаунт администратора кластера, создаем область имен gitlab
make prepear-init
```
## 4:
```bash
# подымаем гитлаб и зависимости(redis, postgres)
make gitlab-up
```
## 5:
```bash
# подымаем gitlab runner
make gitlab-runner-up
```
# Для деплоя в с валидным доменом (а не с самоподписаным)
## 1:
```bash
# Проверяем сертификат (certificates или certificate?)
# Создается новый ресурс CertificateRequest (если самоподписанный - не нужно)
sudo kubectl describe certificates gitlab-home -n gitlab
```
## 2:
ищем строчку:
```
Created new CertificateRequest resource "gitlab-home-s94nj"
```
* gitlab-home-s94nj - используем дальше:
```bash
# отметка о создании Order(если самоподписанный - не нужно)
sudo kubectl describe certificaterequest gitlab-home-s94nj -n gitlab
```
## 3:
```bash
# Статус проверки (самоподписанный не видит)
sudo kubectl describe challenges gitlab-home-s94nj -n gitlab
```

```bash
$ kubectl get certs
NAME             AGE
ccp-mysql-cert   5m

$ kubectl get cert ccp-mysql-cert -o=jsonpath='{.spec.secretName}'
ccp-mysql-cert-secret

$ kubectl get secret ccp-mysql-cert-secret
NAME                    TYPE                DATA   AGE
ccp-mysql-cert-secret   kubernetes.io/tls   2      73m

# delete cert
$ kubectl delete cert ccp-mysql-cert 
certificate.certmanager.k8s.io "ccp-mysql-cert" deleted

$ kubectl get certs
NAME          AGE

# stale secret of deleted cert still exists
$ kubectl get secret ccp-mysql-cert-secret
NAME                    TYPE                DATA   AGE
ccp-mysql-cert-secret   kubernetes.io/tls   2      74m
```

# Добавляем самоподписанный сертификат в клиентскую систему

```bash
kubectl -n gitlab get secret gitlab-home-tls -o json | jq -r '.data["tls.crt"]' | base64 -d > ca.crt
mkdir -p /etc/docker/certs.d/reg.gitlab.dev.lan
cp docker_reg_certs / domain.crt /etc/docker/certs.d/reg.gitlab.dev.lan/ca.crt
cp docker_reg_certs / domain.crt /usr/local/share/ca-certificates/ca.crt
update-ca-certificates
```

# Create a new registry authentication (RA) certificate and key
```
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout ./k8s/registry/secrets/registry-auth.key -out ./k8s/registry/secrets/registry-auth.crt
```
Copy or move RA files into folder named `certs`
Generate `dhparam.pem` file
```bash
openssl dhparam -out ./k8s/registry/secrets/dhparam.pem 2048
```
Copy or move `dhparam.pem` file into `certs`

# Примечания
Ключь
gitlab_rails['registry_key_path'] = "/certs/tls.key"
заполняется из файла сертификата
registry['internal_key'] = "---BEGIN RSA PRIVATE KEY---\nMIIEpQIBAA\n"

# Реест отвалился с self-signed ключем домена