#  2. Test connection using node

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
nvm install 20
```

```js
var express = require('express');
var app = express();

app.listen(3000, '0.0.0.0', function(err) {
    if(err){
       console.log(err);
       } else {
       console.log("listen:3000");
    }
});

//something useful
app.get('*', function(req, res) {
  res.status(200).send('ok')
});
```

```bash
node server.js
```

```bash
curl localhost:3000
curl 192.168.56.100:3000
```

# 3. Install Docker

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

```bash
sudo docker run hello-world
```

## Service
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

## Docker Cgroup Driver

It is crucial to change docker cgroup Driver after install or you get error regarding “Docker group driver detected cgroupfs instead systemd” on cluster initialization. It is easy, and should be done on all nodes (master and workers).

```bash
sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2"
}
EOF
```

```bash
sudo systemctl restart docker
sudo docker info | grep -i cgroup
```

# 4. Disable swap

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

# 5. Enable IP forwarding

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```


# 6. Containerd

```bash
containerd config default | sudo tee /etc/containerd/config.toml
```
sudo vim /etc/containerd/config.toml

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

```bash
sudo systemctl restart containerd
```


sudo vim /etc/containerd/config.toml
upgrade sandbox_image = "registry.k8s.io/pause:3.9" <---- verify this is needed




# 7. Install Kubernetes

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.100
```

# 8. Setup Kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

# 9. Install CNI
https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml 
```

# 10. Enable master node to run pods

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```


# 11. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

# 12. Install Nginx Ingress Controller
External IP is the IP of the master node, 192.168.50.101
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.externalIPs[0]=192.168.56.100
```

NAME: ingress-nginx
LAST DEPLOYED: Mon Nov 13 18:43:37 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace default get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls

## If external IP is not set, update svc to use the IP of the master node inplace

```bash
kubectl edit svc ingress-nginx-controller -n ingress-nginx
kubectl patch svc ingress-nginx-controller -p '{"spec":{"externalIPs":["192.168.56.101"]}}'
```


# Setup NFS Server

```bash
sudo apt-get install nfs-kernel-server -y
sudo mkdir -p /mnt/nfs_share
sudo chown nobody:nogroup /mnt/nfs_share/
sudo chmod 777 /mnt/nfs_share/
```


vim /etc/exports
```txt
/mnt/nfs_share *(rw,sync,no_subtree_check)
```

```bash
sudo service nfs-kernel-server restart
sudo exportfs -a
sudo exportfs
```

# Configure Kubernetes NFS Client Provisioner, option 1 (deprecated)
Create nfs-pv.yaml
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.56.100
    path: /mnt/nfs_share
  volumeMode: Filesystem
```

```bash
kubectl apply -f nfs-pv.yaml
```

Create nfs-pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  volumeName: nfs-pv
```

```bash
kubectl apply -f nfs-pvc.yaml
```

Create nfs-pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-pod
spec:
  containers:
    - name: nfs-pod
      image: nginx
      volumeMounts:
        - name: nfs-pv
          mountPath: /mnt/nfs
  volumes:
    - name: nfs-pv
      persistentVolumeClaim:
        claimName: nfs-pvc
```

```bash
kubectl apply -f nfs-pod.yaml
```

```bash
kubectl exec -it nfs-pod -- /bin/bash
```

```bash
echo "Hello World" > /mnt/nfs/index.html
```

Create storageclass.yaml
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: kubernetes.io/nfs
parameters:
  archiveOnDelete: "false"
```

```bash
kubectl apply -f storageclass.yaml
```

```bash
kubectl get storageclass
```



# Configure Kubernetes NFS Client Provisioner, option 2

```bash
kubectl create namespace nfs-storage
```

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.56.100 \
    --set nfs.path=/mnt/nfs_share \
    --set storageClass.name=nfs-storage \
    --namespace nfs-storage
```

```bash
kubectl get storageclass
```

Create nfs-pvc.yaml
vim nfs-pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-storage
```

```bash
kubectl apply -f nfs-pvc.yaml
```

Define nfs-storage as default storage class (if not already done in the previous nfs-pvc.yaml)
```bash
kubectl patch storageclass nfs-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```



# Install prometheus using helm and nfs storageclass

## Uninstall prometheus
```bash
helm uninstall prometheus
```

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  --set server.persistentVolume.size=1Gi \
  --set alertmanager.persistentVolume.size=1Gi
```

Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "nfs-subdir-external-provisioner" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
NAME: prometheus
LAST DEPLOYED: Mon Nov 13 19:12:54 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.default.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9090


The Prometheus alertmanager can be accessed via port 9093 on the following DNS name from within your cluster:
prometheus-alertmanager.default.svc.cluster.local


Get the Alertmanager URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9093
#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################


The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
prometheus-prometheus-pushgateway.default.svc.cluster.local


Get the PushGateway URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus-pushgateway,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9091

For more information on running Prometheus, visit:
https://prometheus.io/


# Expose prometheus using ingress-nginx-controller

vim prometheus-ingress.yaml
```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: prometheus.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-server
            port:
              number: 80
```

```bash
kubectl apply -f prometheus-ingress.yaml
```

```bash
kubectl get ingress
```

Update hosts file
```bash
echo "192.168.56.100 prometheus.example.com" | sudo tee -a /etc/hosts
```

```bash
curl http://prometheus.example.com
```


echo "192.168.56.100 grafana.example.com" | sudo tee -a /etc/hosts

curl http://grafana.example.com

# show iptaables rules
sudo iptables -L -n -v

# Reset iptables rules and open all
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
