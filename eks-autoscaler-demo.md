```sh
set -Eeuo pipefail
# Basic context for our cluster
export CLUSTER_NAME="interview-ca-cluster"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
# Discover the latest supported Kubernetes version for EKS
export EKS_LATEST_VERSION="$( aws eks describe-addon-versions
--region "$AWS_REGION"
--query 'addons[].compatibilities[].clusterVersion'
--output text | tr '\t' '\n' | sort -uV | tail -1 || true )"
# Fallback to a recent version if discovery fails
: "${EKS_LATEST_VERSION:=1.33}"
echo "Using: Account=$AWS_ACCOUNT_ID Region=$AWS_REGION Cluster=$CLUSTER_NAME K8s=$EKS_LATEST_VERSION"

```

demo-cluster.yml

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
name: ${CLUSTER_NAME}
region: ${AWS_REGION}
version: "${EKS_LATEST_VERSION}"
managedNodeGroups:
- name: managed-ng-1
minSize: 1
desiredCapacity: 1
maxSize: 5
instanceType: t3.medium
volumeSize: 20
labels: { role: worker }
# Required tags for Cluster Autoscaler autodiscovery
tags:
k8s.io/cluster-autoscaler/enabled: "true"
k8s.io/cluster-autoscaler/${CLUSTER_NAME}: "owned"

```

`eksctl create cluster -f ./demo-cluster.yaml`

`aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"`

```sh
eksctl utils associate-iam-oidc-provider \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER_NAME" \
  --approve
```

```json
// cluster-autoscaler-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true"
        },
        "StringLike": {
          "aws:ResourceTag/k8s.io/cluster-autoscaler/*": "owned"
        }
      }
    }
  ]
}

```

```sh

# Create the policy and capture its ARN
export CA_POLICY_ARN="$(
aws iam create-policy
--policy-name AmazonEKSClusterAutoscalerPolicy
--policy-document file://./cluster-autoscaler-policy.json
--query "Policy.Arn" --output text 2>/dev/null ||
aws iam list-policies --scope Local
--query "Policies[?PolicyName=='AmazonEKSClusterAutoscalerPolicy'].Arn | [0]"
--output text
)"
echo "CA policy ARN: $CA_POLICY_ARN"
```

```sh
eksctl create iamserviceaccount
--cluster "$CLUSTER_NAME"
--region "$AWS_REGION"
--namespace kube-system
--name cluster-autoscaler
--attach-policy-arn "$CA_POLICY_ARN"
--approve
--override-existing-serviceaccounts
```

`kubectl -n kube-system get sa cluster-autoscaler -o yaml`

`helm repo add autoscaler https://kubernetes.github.io/autoscaler`
`helm repo update`

```sh
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set nameOverride=aws-cluster-autoscaler \
  --set cloudProvider=aws \
  --set awsRegion="$AWS_REGION" \
  --set autoDiscovery.clusterName="$CLUSTER_NAME" \
  --set expander=least-waste \
  --set rbac.serviceAccount.create=false \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.scale-down-unneeded-time=5m \
  --set extraArgs.skip-nodes-with-local-storage=false \
  --set extraArgs.skip-nodes-with-system-pods=false

```

```yaml
# scale-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scale-test
  namespace: default
spec:
  replicas: 20
  selector:
    matchLabels: { app: scale-test }
  template:
    metadata:
      labels: { app: scale-test }
    spec:
      containers:
        - name: pause
          image: registry.k8s.io/pause:3.9
          resources:
            requests: { cpu: "200m", memory: "256Mi" }
            limits:   { cpu: "200m", memory: "256Mi" }
```

`kubectl apply -f ./scale-test.yaml`
`kubectl get pods -l app=scale-test`
# Tail the logs of the Cluster Autoscaler deployment
`kubectl -n kube-system logs -f deploy/cluster-autoscaler-aws-cluster-autoscaler`

`kubectl get nodes -w`

`kubectl delete -f ./scale-test.yaml`

`kubectl -n kube-system get sa cluster-autoscaler -o yaml`

`helm -n kube-system uninstall cluster-autoscaler || true` # uninstall CA

`eksctl delete cluster --name "$CLUSTER_NAME" --region "$AWS_REGION"`

`aws iam delete-policy --policy-arn "$CA_POLICY_ARN"`


