#!/bin/sh

dockerHost=$(minikube service nxrm-service --url | sed -n 3p | sed 's/^http:\/\///g')

docker build --tag jenkins-docker -f ./jenkins/Dockerfile .
docker login -u admin -p admin123 $dockerHost
docker tag jenkins-docker $dockerHost/jenkins-docker
docker push $dockerHost/jenkins-docker

sed -e "s#\${dockerRegistry}#${dockerHost}#g" ./jenkins/jenkins.yaml > ./jenkins/jenkins.yaml.tmp

kubectl create -f ./jenkins/jenkins.yaml.tmp
