# Vault Minikube Demo
A demo of how one can achieve multiple intermediate CAs on Vault PKI secrets engines split across multiple Vault Namespaces, and how these can issue certificates to a vault client nginx container running on Kubernetes (Minikube)

## Software Requirements
This demo was tested using the following software:
Minikube
```
$ minikube version
minikube version: v1.17.1
commit: 043bdca07e54ab6e4fc0457e3064048f34133d7e
```
HashiCorp Vault 1.6.2 (Note, Vault Enterprise is necessary for demo since placement of PKI secrets engines on Namespaces is demonstrated).
```
$ vault version
Vault v1.6.2+ent
```
Helm 3.3.0:
```
$ helm version
version.BuildInfo{Version:"v3.3.0", GitCommit:"8a4aeec08d67a7b84472007529e8097ec3742105", GitTreeState:"dirty", GoVersion:"go1.14.6"}
```
OS X Catalina 10.15.6:
```
$ sw_vers
ProductName:	Mac OS X
ProductVersion:	10.15.6
BuildVersion:	19G2021
```

It may be possible to implement the demo with other versions of the above software, but this is neither tested
or guaranteed.

## Pre-Steps:
1. Install Minikube
1. Install HashiCorp Vault
1. Install Helm
1. Start Minikube using the `minikube start` command.
1. Identify the ip address of your Minikube server using the following command:
```
$ minikube ip
[IP Address]
```

1. If you are running Vault Enterprise, place a valid license key in a file called `license-vault.txt` in
this directory. The script `0-init-vault.sh` will automatically pick this up and apply it.
1. Add in your local IP address into a file called `my_ip.txt`
1. Run each of the scripts in order starting from 0-... through to 7-...
1. Once scripts have run and pods deployed into vault-demo project are ready, access the following address
in your web browser `https://$(minikube ip):32443`.
Observe that the certificates have a short TTL and are issued by the untrusted CA colin.testing.
1. When you are ready to kill the demo, run `99-kill-vault.sh` to kill the Vault dev server. Then simply run `minikube stop` or `minikube delete` to stop or delete the minikube deployment. 

## Warning
This demo is provided as-is with no support or guarantee. It makes no claim as to "production-readiness" in areas including but not limited to:
- Configuration of Vault (including unsealing and configuring Vault, configuration of PKI secrets engine and so on)
- Configuration of Kubernetes
- Deployment of applications onto Kubernetes
