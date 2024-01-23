#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo reboot

sudo sysctl fs.inotify.max_user_instances=1280
sudo sysctl fs.inotify.max_user_watches=655360

echo "fs.inotify.max_user_instances=1280" | sudo tee -a  /etc/sysctl.conf
echo "fs.inotify.max_user_watches=655360" | sudo tee -a  /etc/sysctl.conf

sudo snap install microk8s --channel 1.24/stable --classic
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
newgrp microk8s
microk8s enable dns hostpath-storage ingress metallb:150.0.0.1-150.0.0.128 dashboard helm3 registry:size=100Gi

sudo snap install kubectl --classic
mkdir -p ~/.kube
microk8s config > ~/.kube/config


sudo snap install juju --channel 2.9/stable --classic
juju bootstrap microk8s

#Kubeflow
juju add-model kubeflow
juju deploy ./kubeflow-bundle.yaml -m kubeflow --trust

juju run-action kubeflow-profiles/0 create-profile username=admin profilename=admin -n kubeflow --wait

kubectl apply -f pod-defaults.yaml -n admin

#Data Sources
juju add-model datasources
juju deploy ./mysql-bundle.yaml -m datasources --trust

sudo apt install mysql-client-core-8.0 jq unzip -y

#Opensearch
sudo snap install helm
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

sudo sysctl vm.max_map_count=262144 -w 
helm install os -f ./env/os-values.yaml opensearch/opensearch -n vectorstore
helm install os-dash -f ./env/os-dash-values.yaml opensearch/opensearch-dashboards -n vectorstore

#Conda
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
