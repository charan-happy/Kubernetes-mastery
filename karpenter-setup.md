
1. **Initial setup:** Karpenter operates directly within your kubernetes cluster. For it to function, it requires permissions to interact with the underlying cloud provider-AWS in this case-to manage resources

2. Granting Permissions: The process involves setting up AWS IRSA(IAM roles for service account). This setup allows your cluster to securely make requests to AWS Services, empowering Karpenter to access necessary informaiton about EC2 instance types and to create or terminate EC2 instances as required

3. Deploying Karpenter: With the necessary permissions configured, Karpenter is installed using a Helm chart. This step integrates karpenter into your kubernetes environment, ready to manage node provisioning

--> Karpenter introduces the concept of NodePools to define how it should manage unschedulable pods and the provisioning of nodes. You'll need to specify various behaviors and constraints for these NodePools, such as node disruption policies and resource limits.



As an example, how nodepool with a trio of budget- The first allows 15% of nodes to be disrupted, the second caps disruptions at 6 once there are over 40 nodes, and the third prevents any disruptions during the first 15 minutes of each day. Karpenter would calculate the allowable disruptions based on these budgets, ensuring it doesn't exceed any of the specified limits.


```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # 30 * 24h = 720h
    budgets:
    - nodes: "15%"
      schedule: "@daily"
      duration: 15m
```