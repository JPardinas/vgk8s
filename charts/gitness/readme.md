# 1. Create a self-signed certificate

mkdir certs

## Create a private key for the server
openssl genpkey -algorithm RSA -out certs/server-key.pem

## Create a self-signed certificate for the server using the private key
openssl req -new -key certs/server-key.pem -out certs/server-csr.pem
openssl x509 -req -in certs/server-csr.pem -signkey certs/server-key.pem -out certs/server-cert.pem


# 2. Create a Kubernetes secret
kubectl create secret tls svc-tls-secret --cert=certs/server-cert.pem --key=certs/server-key.pem -n gitness