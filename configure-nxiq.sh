#!/bin/sh

license=$1
newAdminPassword=${2:-"admin"}

nxiqUrl=$(minikube service nxiq-service --url)
cookies='./nxiq/cookies.tmp'

rm $cookies

curl \
    -u 'admin:admin123' \
    -c $cookies -b $cookies \
    $nxiqUrl/rest/user/session

curl \
    -u 'admin:admin123' \
    -c $cookies -b $cookies \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -F "file=@$license" \
    $nxiqUrl/rest/product/license

curl \
    -u 'admin:admin123' \
    -X PUT \
    -c $cookies -b $cookies \
    -H "Content-Type: application/json" \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -d "{\"oldPassword\":\"admin123\",\"newPassword\":\"$newAdminPassword\"}" \
    $nxiqUrl/rest/user/password

curl \
    -u 'admin:admin123' \
    -X POST \
    -c $cookies -b $cookies \
    -H "Content-Type: application/json" \
    -H "X-CSRF-TOKEN: $(awk '/CLM-CSRF-TOKEN/ { print $NF }' $cookies)" \
    -d '{"id":null,"username":"tcruise","password":"F14AF14A","firstName":"Tom","lastName":"Cruise","email":"jyoung@sonatype.com"}' \
    $nxiqUrl/rest/user

organizationId=$(curl -u admin:$newAdminPassword -X POST -H "Content-Type: application/json" -d '{"name": "Top Guns"}' $nxiqUrl/api/v2/organizations | jq -r .id)

applicationId=$(curl -u admin:$newAdminPassword -X POST -H "Content-Type: application/json" -d "{\"publicId\": \"maverick-library\",\"name\": \"Maverick Library\",\"organizationId\":\"$organizationId\",\"contactUserName\":\"tcruise\",\"applicationTags\": []}" $nxiqUrl/api/v2/applications | jq -r .id)
developerRoleId=$(curl -u admin:$newAdminPassword $nxiqUrl/api/v2/applications/roles | jq -r '.roles[] | select(.name == "Owner") | .id')
curl -u admin:$newAdminPassword -X PUT -H "Content-Type: application/json" -d "{\"memberMappings\": [{\"roleId\": \"$developerRoleId\",\"members\": [{\"type\": \"USER\",\"userOrGroupName\": \"tcruise\"}]}]}" $nxiqUrl/api/v2/applications/$applicationId/roleMembers

applicationId=$(curl -u admin:$newAdminPassword -X POST -H "Content-Type: application/json" -d "{\"publicId\": \"miramar-service\",\"name\": \"Miramar Service\",\"organizationId\":\"$organizationId\",\"contactUserName\":\"tcruise\",\"applicationTags\": []}" $nxiqUrl/api/v2/applications | jq -r .id)
developerRoleId=$(curl -u admin:$newAdminPassword $nxiqUrl/api/v2/applications/roles | jq -r '.roles[] | select(.name == "Owner") | .id')
curl -u admin:$newAdminPassword -X PUT -H "Content-Type: application/json" -d "{\"memberMappings\": [{\"roleId\": \"$developerRoleId\",\"members\": [{\"type\": \"USER\",\"userOrGroupName\": \"tcruise\"}]}]}" $nxiqUrl/api/v2/applications/$applicationId/roleMembers
