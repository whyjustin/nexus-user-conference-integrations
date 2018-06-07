#!/bin/sh

iqAdminPassword=${1:-"admin"}

nxiqUrl=$(minikube service nxiq-service --url)
cookies='./nxiq/cookies.tmp'

rm $cookies

curl \
    -u "admin:$iqAdminPassword" \
    -c $cookies -b $cookies \
    $nxiqUrl/rest/user/session

function getHash() {
    hash=$(curl \
        -u "admin:$iqAdminPassword" \
        -H "Content-Type: application/json" \
        -d "{\"components\":[{\"componentIdentifier\": {\"format\":\"maven\",\"coordinates\": {\"artifactId\":\"$2\",\"extension\":\"jar\",\"groupId\":\"$1\",\"version\":\"$3\"}}}]}" \
        $nxiqUrl/api/v2/components/details | jq -r .componentDetails[0].component.hash)
    echo "$hash"
}

function applyNotApplicable() {
    curl \
        -X PUT \
        -u "admin:$iqAdminPassword" \
        -c $cookies -b $cookies \
        -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
        -H "Content-Type: application/json" \
        -d "{\"hash\":\"$1\",\"referenceId\":\"$2\",\"source\":\"cve\",\"status\":\"NOT_APPLICABLE\",\"comment\":\"\"}" \
        $nxiqUrl/rest/securityVulnerabilityOverride/application/miramar-service
}

springExpressionHash=$(getHash "org.springframework" "spring-expression" "5.0.4.RELEASE")
applyNotApplicable $springExpressionHash "CVE-2018-1257"
applyNotApplicable $springExpressionHash "CVE-2018-1270"

jacksonDataBindHash=$(getHash "com.fasterxml.jackson.core" "jackson-databind" "2.9.4")
applyNotApplicable $jacksonDataBindHash "CVE-2018-7489"

securityHighPolicyId=$(curl \
    -u admin:$iqAdminPassword \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    $nxiqUrl/rest/policy/organization/ROOT_ORGANIZATION_ID/export | jq -r .policies[11].id)

securityHighConstraintId=$(curl \
    -u admin:$iqAdminPassword \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    $nxiqUrl/rest/policy/organization/ROOT_ORGANIZATION_ID/export | jq -r .policies[11].constraints[0].id)

curl \
    -X PUT \
    -u admin:$iqAdminPassword \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    -d "{\"id\":\"$securityHighPolicyId\",\"name\":\"Security-High\",\"ownerId\":\"ROOT_ORGANIZATION_ID\",\"enabled\":true,\"threatLevel\":9,\"constraints\":[{\"id\":\"$securityHighConstraintId\",\"name\":\"High risk CVSS score\",\"enabled\":true,\"operator\":\"AND\",\"conditions\":[{\"conditionTypeId\":\"SecurityVulnerabilitySeverity\",\"operator\":\">=\",\"value\":\"7\"},{\"conditionTypeId\":\"SecurityVulnerabilitySeverity\",\"operator\":\"<\",\"value\":\"10\"},{\"conditionTypeId\":\"SecurityVulnerabilityStatus\",\"operator\":\"is not\",\"value\":\"NOT_APPLICABLE\"},{\"conditionTypeId\":\"MatchState\",\"operator\":\"is\",\"value\":\"exact\"}]}],\"actions\":{},\"notifications\":{\"userNotifications\":[],\"roleNotifications\":[],\"jiraNotifications\":[]}}" \
    $nxiqUrl/rest/policy/organization/ROOT_ORGANIZATION_ID

securityMediumPolicyId=$(curl \
    -u admin:$iqAdminPassword \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    $nxiqUrl/rest/policy/organization/ROOT_ORGANIZATION_ID/export | jq -r .policies[13].id)

securityMediumConstraintId=$(curl \
    -u admin:$iqAdminPassword \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    $nxiqUrl/rest/policy/organization/ROOT_ORGANIZATION_ID/export | jq -r .policies[13].constraints[0].id)

curl \
    -X PUT \
    -u admin:$iqAdminPassword \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    -d "{\"id\":\"$securityMediumPolicyId\",\"name\":\"Security-Medium\",\"ownerId\":\"ROOT_ORGANIZATION_ID\",\"enabled\":true,\"threatLevel\":7,\"constraints\":[{\"id\":\"$securityMediumConstraintId\",\"name\":\"Medium risk CVSS score\",\"enabled\":true,\"operator\":\"AND\",\"conditions\":[{\"conditionTypeId\":\"SecurityVulnerabilitySeverity\",\"operator\":\">=\",\"value\":\"4\"},{\"conditionTypeId\":\"SecurityVulnerabilitySeverity\",\"operator\":\"<\",\"value\":\"7\"},{\"conditionTypeId\":\"SecurityVulnerabilityStatus\",\"operator\":\"is not\",\"value\":\"NOT_APPLICABLE\"},{\"conditionTypeId\":\"MatchState\",\"operator\":\"is\",\"value\":\"exact\"}]}],\"actions\":{},\"notifications\":{\"userNotifications\":[],\"roleNotifications\":[],\"jiraNotifications\":[]}}" \
    $nxiqUrl/rest/policy/organization/ROOT_ORGANIZATION_ID

webmvcHash=$(getHash "org.springframework" "spring-webmvc" "5.0.4.RELEASE")
applyNotApplicable $webmvcHash "CVE-2018-1271"

topGunsOrganizationId=$(curl \
    -u admin:$iqAdminPassword \
    $nxiqUrl/api/v2/organizations | jq -r .organizations[2].id)

componentSimilarPolicyId=$(curl \
    -u admin:$iqAdminPassword \
    $nxiqUrl/api/v2/policies | jq -r .policies[2].id)

curl \
    -u "admin:$iqAdminPassword" \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -H "Content-Type: application/json" \
    -d "{\"hash\":null,\"policyId\":\"$componentSimilarPolicyId\",\"ownerId\":\"$topGunsOrganizationId\",\"comment\":\"\"}" \
    $nxiqUrl/rest/policyWaiver/organization/$topGunsOrganizationId

nxrmUrl=$(minikube service nxrm-service --url | sed -n 1p)

miramarServiceId=$(curl \
    -u admin:admin123 \
    $nxrmUrl/service/rest/beta/components?repository=maven-releases | jq -r .items[1].id)

curl \
    -X DELETE \
    -u admin:admin123 \
    $nxrmUrl/service/rest/beta/components/$miramarServiceId

jenkinsAdminPassword=${2:-"admin123"}

jenkinsUrl=$(minikube service jenkins-service --url)
crumb=$(curl "$jenkinsUrl/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" -u admin:$jenkinsAdminPassword)

curl  \
    -X POST \
    -u admin:$jenkinsAdminPassword \
    -H 'application/x-www-form-urlencoded' \
    -H $crumb \
    $jenkinsUrl/job/miramar-service/doDelete

curl  \
    -X POST \
    -u admin:$jenkinsAdminPassword \
    -H 'application/x-www-form-urlencoded' \
    -H $crumb \
    $jenkinsUrl/job/miramar-service-deploy/doDelete

curl \
    -u admin:$jenkinsAdminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    --data-binary @./jenkins/miramar-service-pipeline-job.xml.tmp \
    $jenkinsUrl/createItem?name=miramar-service

curl \
    -u admin:$jenkinsAdminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    --data-binary @./jenkins/miramar-service-deploy-pipeline-job.xml.tmp \
    $jenkinsUrl/createItem?name=miramar-service-deploy

curl \
    -X POST \
    -u admin:$jenkinsAdminPassword \
    -H 'Content-Type: text/xml' \
    -H $crumb \
    $jenkinsUrl/job/miramar-service/build
