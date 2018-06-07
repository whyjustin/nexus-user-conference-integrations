#!/bin/sh

kubectl delete deployment nxiq-deployment
kubectl delete service nxiq-service

if [ "$1" == "-D" ]; then
    kubectl delete pvc nxiq-pv-claim
    kubectl delete pv nxiq-pv
fi
