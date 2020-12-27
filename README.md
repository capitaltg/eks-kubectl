# Dockerized Kubectl for AWS EKS

This docker image allows you to easily run `kubectl` commands against your
AWS EKS cluster from a Docker image or GitHub action.  The docker image
performs a simple `aws eks update-kubeconfig` followed by executing the
`kubectl` command.  When running it, pass the following environment variables:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
KUBE_CLUSTER_NAME
```
and pass the kubectl command to the command line.  For example, to get a list
of deployments:

	docker  run --rm -it --env-file ./kube.env kubectl get deployments

To use this, your IAM user needs to have the `eks:DescribeCluster` permission.  For example,
this AWS IAM policy will allow you to run kubectl commands against the `my-cluster` in AWS
account `123412341234`:

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

To run a `kubectl` command through a GitHub Action, copy the last step from this reference
GitHub action into your workflow:

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
