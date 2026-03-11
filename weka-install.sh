#!/bin/bash
export WEKA_OPERATOR_VERSION=${WEKA_OPERATOR_VERSION}
export WEKA_IMAGE_VERSION=${WEKA_IMAGE_VERSION}
# wipe screen.
clear

echo "Beginning run to install WEKA Operator ${WEKA_OPERATOR_VERSION} and WEKA version ${WEKA_IMAGE_VERSION}..."
echo "...\n...\n...\n"

# Check the helm installation.
echo "Checking if Helm is installed..."
command -v helm version --short >/dev/null 2>&1 || { echo >&2 "Helm version 3+ is required but not installed yet... download and install here: https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"; exit; }
echo "Helm good to go!...\n\n"

# Check the kubectl installation.
echo "Checking if kubectl is installed...\n\n"
command -v kubectl version >/dev/null 2>&1 || { echo >&2 "Kubectl is required but not installed yet... download and install: https://kubernetes.io/docs/tasks/tools/"; exit; }
echo "kubectl good to go!...\n\n"

## Access k8s cluster.
echo "Status of nodes in the cluster....\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes

if [ $? -ne 0 ]; then
  echo
	echo "Error occurred during kubectl get nodes???.Is your KUBECONFIG variable set??"
	echo
	exit;
fi

echo "Deploy Weka operator version ${WEKA_OPERATOR_VERSION}...\n\n"

command helm upgrade --create-namespace --kubeconfig "${KUBECONFIG}" --install weka-operator oci://quay.io/weka.io/helm/weka-operator --namespace weka-operator-system --version ${WEKA_OPERATOR_VERSION:=v1.10.5} --set csi.installationEnabled=true

echo "Weka operator deployment complete...\n\n"

echo "Examining status of pods in weka-operator-system namespace...Pods should be up and running...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=condition=Ready pod --all --timeout=100s --namespace weka-operator-system

if [ $? -ne 0 ]; then
        echo
        echo "Error accessing k8s cluster. Check your KUBECONFIG variable??"
        echo
        exit;
fi

echo "Creating WEKA secret...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create -f secret.yaml

echo "Examining huge pages config on each node.."
echo "Guidelines: https://docs.weka.io/kubernetes/weka-operator-deployments#configure-hugepages-for-kubernetes-worker-nodes"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes -o custom-columns=NAME:.metadata.name,HUGEPAGES-2Mi:.status.allocatable.hugepages-2Mi,HUGEPAGES-1Gi:.status.allocatable.hugepages-1Gi

echo "Create a wekaPolicy to sign drives..\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create -f wekapolicy.yaml

echo "Observing progress of wekaPolicy...Condition is met if policy is in Done Status\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Done wekapolicy/sign-drives --timeout=10s -n weka-operator-system

echo "Print all nodes and the value of their weka.io/weka-drives annotation..."
echo "A non-zero annotation value indicates successful drive signing...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes -o json | jq -r '.items[] | select(.metadata.annotations."weka.io/weka-drives") | .metadata.name,.metadata.annotations."weka.io/weka-drives"'

echo "Deploying wekaCluster weka-operator-system namespace...\n\n"

command envsubst < wekacluster.yaml | kubectl apply -f -

echo "Manifest deployed...Wait for 8 to 9 minutes for everything to be running..."

sleep 30s

echo "Following along with the installation...\n\n"

echo "Observing the status of wekacluster...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get wekacluster -n weka-operator-system

echo "Taking a look at pods in the install namespace...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get pods -n weka-operator-system

echo "Now we wait until the wekacluster reports Ready status....\n\n"

sleep 20s

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Ready wekacluster/cluster1 --timeout=400s -n weka-operator-system 

echo "Success! WekaCluster is up and running...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get wekacluster -n weka-operator-system

echo "Creating wekaclient with WEKA version ${WEKA_IMAGE_VERSION}...\n\n"

command envsubst < wekaclient.yaml | kubectl apply -f -

echo "Waiting for wekaclient to report Ready status...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Running wekaclient/cluster1-client --timeout=400s -n weka-operator-system

echo "wekaClient is up and running!!Next, taking a look at pods in the install namespace...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get pods -n weka-operator-system

echo "CSI is also up and running!...\n\nTime to create a pod and PVC...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" create -f pvcandpod.yaml

echo "Wait for pod and PVC to be ready...\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=condition=Ready pod --all --timeout=100s --namespace default

echo "Pod is running!!!\n\n\n\n\nYou can kubectl exec to the pod and write data at /data/demo!!!!!"

echo "\n\n\nCongratulations!\n\n\n\n"

