## SSH from host

1. Extract vagrant ssh-config IdentityFile, HostName, Port and User into a file

```bash
vagrant ssh-config > ~/.ssh_config
```



## Kubectl from host and ssh-master function

```bash
echo "Setup k alias with kubeconfig"
k() {
    kubectl --kubeconfig=/c/Users/jpard/kube/config --insecure-skip-tls-verify "$@"
}
echo "Setup vgk8s-ssh alias"
vgk8s-ssh() {
    hostname=$(grep HostName ~/.ssh_config | awk '{print $2}')
    port=$(grep Port ~/.ssh_config | awk '{print $2}')
    user=$(grep 'User ' ~/.ssh_config | awk '{print $2}')
    key=$(grep IdentityFile ~/.ssh_config | awk '{print $2}')
    keyAsBashValidPath=$(echo $key | sed 's/\\//g' | sed 's/C:/\/c/g')
    ssh -i $keyAsBashValidPath -p $port $user@$hostname "$@"
}
echo "Setup vgk8s-start alias"
vgk8s-start() {
    echo "Starting vm..."
    output=$(cd /c/Users/jpard/Desktop/project/vgk8s/vagrant && vagrant up)
    echo "$output"
}
echo "Setup vgk8s-stop alias"
vgk8s-stop() {
    echo "Stopping vm..."
    output=$(cd /c/Users/jpard/Desktop/project/vgk8s/vagrant && vagrant halt)
    echo "$output"
}
```

