#!/bin/sh

minikube service jenkins-service
jenkinsDeployment=$(kubectl get pods | grep -o 'jenkins-deployment-[^ ]*')

kubectl logs $jenkinsDeployment

echo 'Configure Jenkins with admin:admin123. Enter return to continue.'
read foo

adminPassword=${1:-"admin123"}

jenkinsUrl=$(minikube service jenkins-service --url)
crumb=$(curl "$jenkinsUrl/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" -u admin:$adminPassword)

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    -d '<jenkins><install plugin="blueocean@1.5.0" /></jenkins>' \
    $jenkinsUrl/pluginManager/installNecessaryPlugins

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    -d '<jenkins><install plugin="nexus-jenkins-plugin@3.0.20180425-130011.728733c" /></jenkins>' \
    $jenkinsUrl/pluginManager/installNecessaryPlugins

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    -d '<jenkins><install plugin="config-file-provider@2.18" /></jenkins>' \
    $jenkinsUrl/pluginManager/installNecessaryPlugins

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    -d '<jenkins><install plugin="pipeline-utility-steps@2.1.0" /></jenkins>' \
    $jenkinsUrl/pluginManager/installNecessaryPlugins

curl \
    -u admin:$adminPassword \
    -H $crumb \
    --data-urlencode 'json={
    "": "0",
    "credentials": {
        "scope": "GLOBAL",
        "id": "docker-credential-id",
        "username": "admin",
        "password": "admin123",
        "description": "docker-credential-id",
        "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
    }
    }' \
    $jenkinsUrl/credentials/store/system/domain/_/createCredentials

curl \
    -u admin:$adminPassword \
    -H $crumb \
    --data-urlencode 'json={
    "": "0",
    "credentials": {
        "scope": "GLOBAL",
        "id": "nxiq-credential-id",
        "username": "tcruise",
        "password": "F14AF14A",
        "description": "nxiq-credential-id",
        "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
    }
    }' \
    $jenkinsUrl/credentials/store/system/domain/_/createCredentials

echo 'Sleeping 60 sec for plugin installation...'
sleep 60

nxiqUrl=$(minikube service nxiq-service --url)
sed -e "s#\${nxiqUrl}#${nxiqUrl}#g" ./jenkins/configure-nxiq.groovy > ./jenkins/configure-nxiq.groovy.tmp

curl \
    -u admin:$adminPassword \
    -H $crumb \
    -d "script=$(cat ./jenkins/configure-nxiq.groovy.tmp)" \
    $jenkinsUrl/scriptText

nexusRepositoryUrl=$(minikube service nxrm-service --url | sed -n 1p)

cp ./jenkins/configure-nxrm-settings.xml ./jenkins/configure-nxrm-settings.xml.tmp
sed -i '' "s#\${nexusRepositoryUrl}#${nexusRepositoryUrl}#g" ./jenkins/configure-nxrm-settings.xml.tmp

curl \
    -u admin:$adminPassword \
    -H $crumb \
    --data-urlencode "json={
    \"\": \"0\",
    \"config\": {
        \"stapler-class\": \"org.jenkinsci.plugins.configfiles.maven.GlobalMavenSettingsConfig\",
        \"id\": \"nxrm-settings.xml\",
        \"providerId\": \"org.jenkinsci.plugins.configfiles.maven.GlobalMavenSettingsConfig\",
        \"name\": \"nxrm-settings\",
        \"comment\": \"nxrm-settings\",
        \"isReplaceAll\": true,
        \"content\": \"$(cat ./jenkins/configure-nxrm-settings.xml.tmp | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g')\",
        \"\": \"\"
    }
    }" \
    $jenkinsUrl/configfiles/saveConfig

gitLabUrl=$(minikube service gitlab-service --url)

sed -e "s#<url>\${gitlab-url}/#<url>$gitLabUrl/#g" ./jenkins/miramar-service-pipeline-job.xml > ./jenkins/miramar-service-pipeline-job.xml.tmp

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    --data-binary @./jenkins/miramar-service-pipeline-job.xml.tmp \
    $jenkinsUrl/createItem?name=miramar-service

sed -e "s#<url>\${gitlab-url}/#<url>$gitLabUrl/#g" ./jenkins/miramar-service-deploy-pipeline-job.xml > ./jenkins/miramar-service-deploy-pipeline-job.xml.tmp

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    --data-binary @./jenkins/miramar-service-deploy-pipeline-job.xml.tmp \
    $jenkinsUrl/createItem?name=miramar-service-deploy

sed -e "s#<url>\${gitlab-url}/#<url>$gitLabUrl/#g" ./jenkins/maverick-library-pipeline-job.xml > ./jenkins/maverick-library-pipeline-job.xml.tmp

curl \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    --data-binary @./jenkins/maverick-library-pipeline-job.xml.tmp \
    $jenkinsUrl/createItem?name=maverick-library

curl \
    -X POST \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    $jenkinsUrl/job/miramar-service/build

curl \
    -X POST \
    -u admin:$adminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    $jenkinsUrl/job/maverick-library/build
