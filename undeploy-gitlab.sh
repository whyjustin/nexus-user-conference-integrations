#!/bin/sh

kubectl delete deployment gitlab-deployment
kubectl delete service gitlab-service

if [ "$1" == "-D" ]; then
    kubectl delete pvc gitlab-pv-claim
    kubectl delete pv gitlab-pv
fi
