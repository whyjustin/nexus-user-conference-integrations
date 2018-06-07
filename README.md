# From the Source: Nexus Platform Integrations

This is code used during the [From the Source: Nexus Platform Integrations](https://nexususerconference2018.sched.com/event/EoTs/from-the-source-nexus-platform-integrations) talk of the Nexus User Conference. It configures a minikube service with Jenkins, GitLab, Nexus Repository Manager and Nexus IQ Server. Deploys a couple sample applications and pipelines to deliver them. Requires [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/).

```
minikube start --vm-driver=hyperkit --memory 6144 --cpus 3

./deploy-nxrm.sh
./deploy-nxiq.sh

kubectl get pods
# Wait until pods return STATUS Running

./configure-nxrm.sh

kubectl get pods
# Wait until pods return STATUS Running

./configure-nxiq.sh {path-to-lifecycle-license.lic}

./deploy-gitlab.sh

minikube service nxrm-service --url | sed -n 3p | sed 's/^http:\/\///g'
# Adjust local Docker instance to allow the above insecure-registry (Nexus Repository Hosted Docker)

./deploy-jenkins

kubectl get pods
# Wait until pods return STATUS Running

./configure-gitlab.sh
# Configure root user with admin123 password and create token with api access for root user.

./configure-jenkins.sh
# Use password from log to unlock, install suggested plugins, configure admin:admin123 user.

./deploy-miramar-service.sh
```

To access any of the services, minikube provides the urls assoicated with them.

```
minikube service nxrm-service --url
minikube service nxiq-service --url
minikube service gitlab-service --url
minikube service jenkins-service --url
```

All services can be undeployed with the undeploy scripts, such as 

```
./undeploy-gitlab.sh
```

The -D switch will delete any pv associated with the service.
