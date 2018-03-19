# Kubernetes 移除 Node

- [Safely Drain a Node while Respecting Application SLOs](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)

```
# kubectl get nodes
NAME              STATUS    AGE       VERSION
k8s-master        Ready     27m       v1.7.5
k8s-node-1        Ready     44m       v1.7.5
k8s-test-node-2   Ready     44m       v1.7.5
k8s-test-node-3   Ready     43m       v1.7.5

# kubectl drain k8s-test-node-3
node "k8s-test-node-3" cordoned
error: DaemonSet-managed pods (use --ignore-daemonsets to ignore): kube-flannel-ds-str6l

# kubectl drain k8s-test-node-3 --ignore-daemonsets
node "k8s-test-node-3" already cordoned
WARNING: Ignoring DaemonSet-managed pods: kube-flannel-ds-str6l
pod "nginx-deployment-431080787-qhwm7" evicted
node "k8s-test-node-3" drained
```
