#!/bin/sh

minikube service gitlab-service
gitlabDeployment=$(kubectl get pods | grep -o 'gitlab-deployment-[^ ]*')

echo 'Configure Gitlab with root:admin123 then create access token.'
echo 'Input access token:'
read accessToken

gitLabUrl=$(minikube service gitlab-service --url)

userId=$(curl \
    -H "PRIVATE-TOKEN: $accessToken" \
    -d 'email=jyoung@sonatype.com' \
    -d 'password=F14AF14A' \
    -d 'username=tcruise' \
    -d 'name=Tom Cruise' \
    -d 'skip_confirmation=true' \
    $gitLabUrl/api/v4/users | jq -r .id)

curl \
    -H "PRIVATE-TOKEN: $accessToken" \
    -d "user_id=$userId" \
    -d 'name=miramar-service' \
    -d 'visibility=public' \
    $gitLabUrl/api/v4/projects/user/$userId

curl \
    -H "PRIVATE-TOKEN: $accessToken" \
    -d "user_id=$userId" \
    -d 'name=maverick-library' \
    -d 'visibility=public' \
    $gitLabUrl/api/v4/projects/user/$userId

echo 'Sleeping 30 sec for project allocation...'
sleep 30

gitLabHost=$(echo "$gitLabUrl" | sed 's/^http:\/\///g')
nexusRepositoryHost=$(minikube service nxrm-service --url | sed -n 1p | sed 's/^http:\/\///g')
dockerProxyHost=$(minikube service nxrm-service --url | sed -n 2p | sed 's/^http:\/\///g')
dockerHostedHost=$(minikube service nxrm-service --url | sed -n 3p | sed 's/^http:\/\///g')

cp ./miramar-service/Jenkinsfile.template ./miramar-service/Jenkinsfile
sed -i '' "s#\${dockerProxyHost}#${dockerProxyHost}#g" ./miramar-service/Jenkinsfile
sed -i '' "s#\${nexusRepositoryHost}#${nexusRepositoryHost}#g" ./miramar-service/Jenkinsfile

cp ./miramar-service/Jenkinsfile.deploy.template ./miramar-service/Jenkinsfile.deploy
sed -i '' "s#\${dockerProxyHost}#${dockerProxyHost}#g" ./miramar-service/Jenkinsfile.deploy
sed -i '' "s#\${dockerHostedHost}#${dockerHostedHost}#g" ./miramar-service/Jenkinsfile.deploy

cp ./miramar-service/pom.xml.template ./miramar-service/pom.xml
sed -i '' "s#\${nexusRepositoryHost}#${nexusRepositoryHost}#g" ./miramar-service/pom.xml

cp ./miramar-service/Dockerfile.template ./miramar-service/Dockerfile
sed -i '' "s#\${nexusRepositoryHost}#${nexusRepositoryHost}#g" ./miramar-service/Dockerfile

cp ./miramar-service/miramar-service.yaml.template ./miramar-service/miramar-service.yaml
sed -i '' "s#\${dockerHostedHost}#${dockerHostedHost}#g" ./miramar-service/miramar-service.yaml

pushd miramar-service

rm -rf .git
git init

git remote add origin $gitLabUrl/tcruise/miramar-service.git
git add .
git commit -m "Initial commit"
git push -u http://tcruise:F14AF14A@$gitLabHost/tcruise/miramar-service.git

popd

cp ./maverick-library/Jenkinsfile.template ./maverick-library/Jenkinsfile
sed -i '' "s#\${dockerProxyHost}#${dockerProxyHost}#g" ./maverick-library/Jenkinsfile
sed -i '' "s#\${nexusRepositoryHost}#${nexusRepositoryHost}#g" ./maverick-library/Jenkinsfile

cp ./maverick-library/pom.xml.template ./maverick-library/pom.xml
sed -i '' "s#\${nexusRepositoryHost}#${nexusRepositoryHost}#g" ./maverick-library/pom.xml

pushd maverick-library

rm -rf .git
git init

git remote add origin $gitLabUrl/tcruise/maverick-library.git
git add .
git commit -m "Initial commit"
git push -u http://tcruise:F14AF14A@$gitLabHost/tcruise/maverick-library.git

popd
