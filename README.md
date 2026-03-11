# weka-k8s-quickstart
This repo contains scripts to deploy and clean-up a WEKA cluster on Kubernetes.

## Pre-Requisites
- Kubernetes cluster.
- Access to a WEKA Secret.

Refer to [this blog](https://balaramesh18.substack.com/i/189672931/pre-requisites) for further instructions.

## Deploy a wekaCluster, wekaClient, and sample workload

Invoke `weka-install.sh` after exporting `WEKA_OPERATOR_VERSION` and `WEKA_IMAGE_VERSION` variables.

https://github.com/user-attachments/assets/1511a95e-ae44-47b7-9ff8-09ab56a07533

## Clean-up

To leave the k8s cluster the way it was before `weka-install.sh` was invoked, use `weka-cleanup.sh`

https://github.com/user-attachments/assets/d822b829-4b90-4b34-aed9-9fdd76698611


