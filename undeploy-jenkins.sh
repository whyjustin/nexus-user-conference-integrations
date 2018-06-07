#!/bin/sh

kubectl delete deployment jenkins-deployment
kubectl delete service jenkins-service

if [ "$1" == "-D" ]; then
    kubectl delete pvc jenkins-pv-claim
    kubectl delete pv jenkins-pv
fi
