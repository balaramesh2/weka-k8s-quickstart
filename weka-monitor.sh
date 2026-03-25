#!/bin/bash
# wipe screen.
clear

echo "\n\nBeginning run to install latest Prometheus version...\n\n"

# Check the helm installation.
echo "\n\nChecking if Helm is installed...\n\n"
command -v helm version --short >/dev/null 2>&1 || { echo >&2 "Helm version 3+ is required but not installed yet... download and install here: https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"; exit; }
echo "\n\nHelm good to go!...\n\n"

# Check the kubectl installation.
echo "\n\nChecking if kubectl is installed...\n\n"
command -v kubectl version >/dev/null 2>&1 || { echo >&2 "Kubectl is required but not installed yet... download and install: https://kubernetes.io/docs/tasks/tools/"; exit; }
echo "\n\nkubectl good to go!...\n\n"

echo "\n\nAdding Helm repos for Prometheus and Grafana...\n\n"

command helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
command helm repo add grafana https://grafana.github.io/helm-charts
command helm repo update

echo "\n\nCreating namespaces for Prometheus and Grafana installs...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create ns prometheus
command kubectl --kubeconfig "${KUBECONFIG}" create ns grafana

echo "\n\nInstalling Prometheus with Helm..\n\n"

command helm upgrade --install prometheus prometheus-community/prometheus --kubeconfig "${KUBECONFIG}" --namespace prometheus

echo "\n\nInstalling Grafana with Helm...\n\n"

command helm upgrade --install grafana grafana/grafana --kubeconfig "${KUBECONFIG}" --namespace grafana -f values-graf.yaml

if [ $? -ne 0 ]; then
        echo
        echo "Error installing Prometheus and Grafana using Helm. Check your KUBECONFIG variable??"
        echo
        exit;
fi

echo "\n\nWaiting for Prometheus and Grafana to be installed...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=condition=Ready pod --all --timeout=200s --namespace grafana

if [ $? -ne 0 ]; then
        echo
        echo "Error installing Grafana using Helm. Check your KUBECONFIG variable??"
        echo
        exit;
fi

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=condition=Ready pod --all --timeout=200s --namespace prometheus

if [ $? -ne 0 ]; then
        echo
        echo "Error installing Prometheus using Helm. Check your KUBECONFIG variable??"
        echo
        exit;
fi

echo "\n\nExposing Grafana and Prometheus UI...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" expose service prometheus-server --namespace prometheus --type=NodePort --target-port=9090 --name=prometheus-server-ext

if [ $? -ne 0 ]; then
        echo
        echo "Error accessing k8s cluster. Check your KUBECONFIG variable??"
        echo
        exit;
fi

command kubectl --kubeconfig "${KUBECONFIG}" expose service grafana --namespace grafana --type=NodePort --target-port=3000 --name=grafana-ext

if [ $? -ne 0 ]; then
        echo
        echo "Error accessing k8s cluster. Check your KUBECONFIG variable??"
        echo
        exit;
fi

echo "\n\nAccess Grafana UI using the address https://node-name:31668\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes

echo "\n\nCredentials for Grafana UI are username:admin and password is below...\n\n"

echo "admin:" || command kubectl --kubeconfig "${KUBECONFIG}" get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
