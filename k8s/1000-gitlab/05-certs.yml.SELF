apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: gitlab-home
  namespace: gitlab
spec:
  secretName: gitlab-home-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: gitlab.dev.lan
  dnsNames:
    - gitlab.dev.lan
    #- reg.gitlab.dev.lan
