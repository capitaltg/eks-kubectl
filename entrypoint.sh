#!/bin/sh

aws eks update-kubeconfig --name $KUBE_CLUSTER_NAME
kubectl $*
