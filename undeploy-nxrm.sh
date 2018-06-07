#!/bin/sh

kubectl delete deployment nxrm-deployment
kubectl delete service nxrm-service

if [ "$1" == "-D" ]; then
    kubectl delete pvc nxrm-pv-claim
    kubectl delete pv nxrm-pv
fi
