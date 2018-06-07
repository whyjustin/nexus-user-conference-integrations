#!/bin/sh

nxrmUrl=$(minikube service nxrm-service --url | sed -n 1p)

curl \
    -u admin:admin123 \
    --insecure \
    --header 'Content-Type: application/json' \
    -d @nxrm/create-docker.json \
    $nxrmUrl/service/rest/v1/script
    
curl \
    -X POST \
    -u admin:admin123 \
    --insecure \
    --header 'Content-Type: text/plain' \
    $nxrmUrl/service/rest/v1/script/CreateDocker/run

curl \
    -u admin:admin123 \
    --insecure \
    --header 'Content-Type: application/json' \
    -d @nxrm/create-npm.json \
    $nxrmUrl/service/rest/v1/script

curl \
    -X POST \
    -u admin:admin123 \
    --insecure \
    --header 'Content-Type: text/plain' \
    $nxrmUrl/service/rest/v1/script/CreateNpm/run

dockerProxyHost=$(minikube service nxrm-service --url | sed -n 2p | sed 's/^http:\/\///g')
dockerHostedHost=$(minikube service nxrm-service --url | sed -n 3p | sed 's/^http:\/\///g')

kubectl create secret docker-registry nxrm-docker-secret --docker-server=$dockerHostedHost --docker-username=admin --docker-password=admin123 --docker-email=jyoung@sonatype.com
sed -i '' "s/\"InsecureRegistry\": \[/\"InsecureRegistry\": \[\"$dockerHostedHost\",\"$dockerProxyHost\",/g" ~/.minikube/machines/minikube/config.json
minikube stop
minikube start --vm-driver=hyperkit --memory 6144 --cpus 4
