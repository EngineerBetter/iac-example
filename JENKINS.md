# Jenkins in Kubernetes (optional)

Firstly you'll need a Kubernetes cluster, we recommend [enabling the inbuilt one
inside Docker Desktop](https://docs.docker.com/desktop/kubernetes/).
Alternatively you could use
[kind](https://kind.sigs.k8s.io/docs/user/quick-start/).

After installation of the cluster, make sure you've selected the docker-desktop
context so that kubectl is talking to the expected cluster. You'll find this by
navigating to Docker -> kubernetes -> docker-desktop.

If you're using Kind, please follow the
[instructions to install a LoadBalancer](https://kind.sigs.k8s.io/docs/user/loadbalancer/)
to your cluster.

## Following along

```terminal
# In order to use the Jenkins CLI and access the UI you'll need to install an
# ingress controller.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/cloud/deploy.yaml

# Install Jenkins in a `jenkins` namespace.
helmfile apply

# Jenkins may take a few minutes to install the first time this command is run,
# you can view the status of the `jenkins` pod with:
kubectl describe pod jenkins-0 -n jenkins
```

Once deployed, access the Jenkins UI by navigating to
[http://localhost/](http://localhost/) and logging in with `admin`/`p4ssw0rd`.