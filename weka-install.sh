#!/bin/bash
export WEKA_OPERATOR_VERSION=${WEKA_OPERATOR_VERSION}
export WEKA_IMAGE_VERSION=${WEKA_IMAGE_VERSION}
# wipe screen.
clear

echo "\n\nBeginning run to install WEKA Operator ${WEKA_OPERATOR_VERSION} and WEKA version ${WEKA_IMAGE_VERSION}..."
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
	echo "\n\nError occurred during kubectl get nodes???.Is your KUBECONFIG variable set??\n\n"
	echo
	exit;
fi

echo "\n\nExamining huge pages config on each node..\n\n"
echo "Guidelines: https://docs.weka.io/kubernetes/weka-operator-deployments#configure-hugepages-for-kubernetes-worker-nodes\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes -o custom-columns='NAME:.metadata.name,HUGEPAGES-2Mi:.status.allocatable.hugepages-2Mi,HUGEPAGES-1Gi:.status.allocatable.hugepages-1Gi'

echo "\n\nDoes this look okay?..Sleeping for 10 seconds..\n\n\n"

sleep 10s

echo "\n\nCreating WEKA Operator namespace and WEKA secret...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create ns weka-operator-system
command kubectl --kubeconfig "${KUBECONFIG}" create -f secret.yaml

echo "\n\nProceeding to deploy Weka operator version ${WEKA_OPERATOR_VERSION}...\n\n"

command helm upgrade --create-namespace --kubeconfig "${KUBECONFIG}" --install weka-operator oci://quay.io/weka.io/helm/weka-operator --namespace weka-operator-system --version ${WEKA_OPERATOR_VERSION:=v1.10.5} --set csi.installationEnabled=true

echo "\n\nWeka operator deployment complete...\n\n"

sleep 2s

echo "\n\nExamining status of pods in weka-operator-system namespace...Pods should be up and running...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=condition=Ready pod --all --timeout=200s --namespace weka-operator-system

if [ $? -ne 0 ]; then
        echo
        echo "Error accessing k8s cluster. Check your KUBECONFIG variable??"
        echo
        exit;
fi

echo "\n\nCreate a wekaPolicy to sign drives..\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create -f wekapolicy.yaml

echo "\n\nObserving progress of wekaPolicy...Condition is met if policy is in Done Status\n\n"

sleep 30s

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Done wekapolicy/sign-drives --timeout=200s -n weka-operator-system

sleep 30s

echo "\n\nPrint all nodes and the value of their weka.io/weka-drives annotation...\n\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes -o custom-columns='NAME:.metadata.name,WEKADRIVES:.metadata.annotations.weka\.io/weka-drives'

sleep 10s 

echo "\n\nDeploying wekaCluster weka-operator-system namespace...\n\n\n"

command envsubst < wekacluster.yaml | kubectl apply -f -

echo "\n\nManifest deployed...Wait for 8 to 9 minutes for everything to be running...\n\n"

sleep 30s

echo "\n\nFollowing along with the installation...\n\n"

sleep 2s

echo "\n\nObserving the status of wekacluster...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get wekacluster -n weka-operator-system

echo "\n\nTaking a look at pods in the install namespace...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get pods -n weka-operator-system

echo "\n\nNow we wait for 16 minutes, or until the wekacluster reports Ready status....\n\n"

sleep 20s

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Ready wekacluster/cluster1 --timeout=800s -n weka-operator-system 

echo "\n\nSuccess! WekaCluster is up and running...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get wekacluster -n weka-operator-system

echo "\n\nCreating wekaclient with WEKA version ${WEKA_IMAGE_VERSION}...\n\n"

command envsubst < wekaclient.yaml | kubectl apply -f -

echo "\n\nWaiting for 8 minutes, or wekaclient to report Ready status...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Running wekaclient/cluster1-client --timeout=400s -n weka-operator-system

echo "\n\nwekaClient is up and running!!Next, taking a look at pods in the install namespace...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get pods -n weka-operator-system

echo "\n\nCSI is also up and running!...\n\nTime to create a pod and PVC...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create -f pvcandpod.yaml

echo "\n\nWait for 100 seconds, or for pod and PVC to be ready...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=condition=Ready pod --all --timeout=100s --namespace default

echo "Pod is running!!!\n\n\n\n\nYou can kubectl exec to the pod and write data at /data/demo!!!!!"

echo "\n\n\nCongratulations!\n\n\n\n"

