# ArgoCD

mkdir -p charts/argo-cd

charts/argo-cd/Chart.yaml
apiVersion: v2
name: argo-cd
version: 1.0.0
dependencies:
  - name: argo-cd
    version: 5.46.8
    repository: https://argoproj.github.io/argo-helm


# Create ArgoCD namespace
kubectl create namespace argocd

charts/argo-cd/values.yaml
argo-cd:
  namespace: argocd
  dex:
    enabled: false
  notifications:
    enabled: false
  applicationSet:
    enabled: false
  server:
    extraArgs:
      - --insecure

helm repo add argo-cd https://argoproj.github.io/argo-helm
helm dep update /charts/argocd/

echo "charts/**/charts" >> .gitignore

helm install argo-cd /charts/argocd/ --namespace argocd


# Create Ingress

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: 
  name: argocd-server-ingress
  namespace: argocd
spec:
  rules:
    - host: argocd.vgk8s.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argo-cd-argocd-server
                port:
                  number: 80
EOF

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Update /etc/hosts with argocd.vgk8s.com using sudo tee, and keeping the previous content
echo "172.20.118.61 argocd.vgk8s.com" | sudo tee -a /etc/hosts

