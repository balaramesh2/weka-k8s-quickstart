#!/bin/bash
export WEKA_OPERATOR_VERSION=${WEKA_OPERATOR_VERSION}
export WEKA_IMAGE_VERSION=${WEKA_IMAGE_VERSION}
# wipe screen.
clear

echo "Beginning run to un-install WEKA Operator ${WEKA_OPERATOR_VERSION} and WEKA version ${WEKA_IMAGE_VERSION}..."
echo "...\n...\n...\n"

# Check the helm installation.
echo "\n\nChecking if Helm is installed...\n\n"
command -v helm version --short >/dev/null 2>&1 || { echo >&2 "Helm version 3+ is required but not installed yet... download and install here: https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"; exit; }
echo "\n\nHelm good to go!...\n\n"

# Check the kubectl installation.
echo "\n\nChecking if kubectl is installed...\n\n"
command -v kubectl version >/dev/null 2>&1 || { echo >&2 "Kubectl is required but not installed yet... download and install: https://kubernetes.io/docs/tasks/tools/"; exit; }
echo "\n\nkubectl good to go!...\n\n"

## Access k8s cluster.
echo "\n\nStatus of nodes in the cluster....\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes

if [ $? -ne 0 ]; then
  echo
	echo "Error occurred during kubectl get nodes???.Is your KUBECONFIG variable set??"
	echo
	exit;
fi

echo "\n\nDelete sample pod and PVC in default namespace.....\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" delete -f pvcandpod.yaml

if [ $? -ne 0 ]; then
  echo
        echo "\n\nError occurred during kubectl delete -f pvcandpod.yaml???.Is your KUBECONFIG variable set??\n\n"
        echo
        exit;
fi

echo "\n\nDelete wekaClient object...\n\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" delete -f wekaclient.yaml

echo "\n\nDelete wekaCluster....\n\n"

if [ $? -ne 0 ]; then
  echo
        echo "\n\nError occurred during kubectl delete -f wekaclient.yaml???.Is your KUBECONFIG variable set??\n\n"
        echo
        exit;
fi

command kubectl --kubeconfig "${KUBECONFIG}" delete -f wekacluster.yaml

echo "\n\nDelete wekaPolicy....\n\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" delete -f wekapolicy.yaml

if [ $? -ne 0 ]; then
  echo
        echo "\n\nError occurred during kubectl delete -f wekapolicy.yaml???.Is your KUBECONFIG variable set??\n\n"
        echo
        exit;
fi

sleep 5s

echo "\n\nTaking a look at pods in the install namespace...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get pods -n weka-operator-system

if [ $? -ne 0 ]; then
  echo
        echo "\n\nError occurred during kubectl get pods???.Is your KUBECONFIG variable set??\n\n"
        echo
        exit;
fi
echo "\n\nDeleting the Weka operator with Helm uninstall\n\n"

command helm uninstall --kubeconfig "${KUBECONFIG}" weka-operator -n weka-operator-system

sleep 5s

echo "\n\nNow we delete the weka-operator-system namespace....\n\n"

sleep 5s

command kubectl --kubeconfig "${KUBECONFIG}" delete ns weka-operator-system

if [ $? -ne 0 ]; then
  echo
        echo "\n\nError occurred during kubectl delete ns weka-operator-system???.Is your KUBECONFIG variable set??\n\n"
        echo
        exit;
fi

echo "\n\n\nUn-install complete....Congratulations!\n\n\n\n"

