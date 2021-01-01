# Dockerized Kubectl for AWS EKS

This docker image allows you to easily run `kubectl` commands against your
AWS EKS cluster from a Docker image, which in turn can be used by a GitHub
action.  The docker image performs a simple `aws eks update-kubeconfig` followed
by executing the `kubectl` command with provided inputs.  When running it, pass
the following environment variables:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
KUBE_CLUSTER_NAME
```
and pass the kubectl command to the command line.  For example, to get a list
of deployments:

	docker run --rm -it --env-file ./kube.env kubectl get deployments

# GitHub Action
To run a `kubectl` command through a GitHub Action, copy the last step from this
reference GitHub action into your workflow:

```
on: push
name: deploy
jobs:
  deploy:
    name: deploy to cluster
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: run kubectl
      uses: capitaltg/eks-kubectl@main
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: us-east-1
        KUBE_CLUSTER_NAME: my-cluster
      with:
        args: get deployments
```

# Security
There are two aspects to EKS security:

1. Authentication
2. Authorization

## Authentication
To use the image, your IAM user needs to have the `eks:DescribeCluster` permission in order
to get an authentication token to your cluster.  For example, this AWS IAM user policy will
allow you to run kubectl commands against the `my-cluster` in AWS account `123412341234`:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "eks:DescribeCluster",
            "Resource": "arn:aws:eks:us-east-1:123412341234:cluster/my-cluster"
        }
    ]
}
```

## Authorization
With the above policy, you will be authenticated to the EKS cluster.  Now you need to make sure
you are authorized to run `kubectl` commands. You can do that by ensuring a `ConfigMap` exists
in the `kube-system` namespace that provides permissions for your IAM user.  For example, you
can run `kubectl edit configmap/aws-auth --namespace=kube-system` to add your new IAM user 
(somenewuser). While the configuration below provides full cluster access to your new user,
in a production system, don't add your new user to the `system:masters` group.  Instead, use
finer-grained authorizations for better security.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::123456789012:role/NodeInstanceRole
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::123456789012:user/somenewuser
      username: somenewuser
```

## Troubleshooting
If you authenticate your user but fail to authorize your IAM user to run EKS commands, you may see
this error:

  `error: You must be logged in to the server (Unauthorized)`

If you have insufficient EKS permissions, you may see an error message like:

  `Error from server (Forbidden): pods is forbidden: User "somenewuser" cannot list resource "pods" in API group "" in the namespace "default"`
