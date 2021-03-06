# Docker container for kubeflow setup

# Creating cluster and setting up kubeflow

## Configure environment

git clone https://github.com/terraform-providers/terraform-provider-aws.git

Set the environment variable KUBEFLOW_DATA_DIR to point to somewhere that includes at least the examples/eks-getting-started directory from the above repo.

You could check this out from within the container but then you'd lose the files when the container is stopped so I prefer to keep them outside and use a volume mount.

Set the following environment variables to the AWS credentials you are going to use:
* AWS_KUBE_ACCESS_KEY_ID
* AWS_KUBE_SECRET_ACCESS_KEY
* AWS_KUBE_DEFAULT_REGION

OPTIONAL: The run-container.sh script will use the latest container hosted on hub.docker.com so you don't need to build a local copy of the container unless you want to. Running make-container.sh will download the required components (terraform, kubectl, ksonnet & kubeflow) and build the docker image.

    ./make-container.sh

Start the container

    ./run-container.sh

## Creating the EKS cluster
The following commands are run within the container in the shell opened by the run-container.sh script

    # Adjust this directory to wherever you put the git repo you checked out earlier
    cd /opt/data/terraform-provider-aws/examples/eks-getting-started/

    terraform apply

    aws eks update-kubeconfig --name terraform-eks-demo --region us-west-2

Allow worker nodes to attach to EKS

    terraform output config_map_aws_auth > config_map_aws_auth.yaml
    kubectl apply -f config_map_aws_auth.yaml

At this point we should have a working K8S cluster with a EBS storage class

It's helpful to have the kubernetes dashboard available

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

    cat > eks-admin-service-account.yaml <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: eks-admin
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: eks-admin
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: eks-admin
      namespace: kube-system
    EOF

    kubectl apply -f eks-admin-service-account.yaml

Get the token to use to login to the dashboard

    kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

    kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &

Then go to: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

## Setting up kubeflow
The following commands need to be run inside the container once the K8S cluster is configured

    kfctl.sh init kubeflow --platform aws
    cd kubeflow
    kfctl.sh generate k8s
    kfctl.sh apply k8s

Port forward for kubeflow UI (needs kubectl 1.13.0 or greater)

    kubectl port-forward svc/ambassador --address 0.0.0.0 -n kubeflow 8080:80 &

## Work around kubeflow 0.4.0 bug
There is a bug in kubeflow 0.4.0 which means that if you are not deploying in a Google GKE environment then the pytorch-operator pod is not installed. This means that the studyjob-controller pod will fail to start and you won't be able to use katib even if you only want to use tensorflow.

The workaround is to manually install pytorch-operator

    cd .../kubeflow/ks_app
    ks apply default -c pytorch-operator

# Commands each time container is started
Unless you take steps to save the output you'lkll need to do the following each time you start the docker container.

Update kubeconfig

    aws eks update-kubeconfig --name terraform-eks-demo --region us-west-2

Get token for dashboard

    kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

Run proxy for dashboard

    kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &

Port forward for kubeflow UI (needs kubectl 1.13.0 or greater)

    kubectl port-forward svc/ambassador --address 0.0.0.0 -n kubeflow 8080:80 &

# Scaling the cluster
The terraform EKS example creates an auto-scaling group with 2 worker nodes. If you need more nodes you can edit the auto scaling group via the autoscaling group section in the AWS EC2 console and set the desired number of workers. You may also need to adjust the max number of machines too. As new machines are created they will automatically be added to the cluster. Likewise reducing the desired number of workers will automatically destroy nodes and remove them from the kubernetes cluster without needing any manual steps.

# Teardown
To remove all resources you can use `terraform destroy`

    cd /opt/data/terraform-provider-aws/examples/eks-getting-started/
    terraform destroy
