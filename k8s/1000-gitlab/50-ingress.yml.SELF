apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab-ing
  namespace: gitlab
  labels:
    app: gitlab
  annotations:
    traefik.ingress.kubernetes.io/redirect-entry-point: https
spec:
  rules:
    - host: gitlab.dev.lan
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: gitlab
              port:
                number: 80
#    - host: reg.gitlab.dev.lan
#      http:
#        paths:
#        - path: /
#          pathType: Prefix
#          backend:
#            service:
#              name: gitlab
#              port:
#                number: 5050
  tls:
    - hosts:
        #- reg.gitlab.dev.lan
        - gitlab.dev.lan
      secretName: gitlab-home-tls
