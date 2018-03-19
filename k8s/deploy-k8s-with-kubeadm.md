# 使用 kubeadm 部署 kubernetes 集群


## 准备

- 2-4 台 host（物理机或虚拟机）
- 操作系统使用最新的 CentOS / Ubuntu x86_64
- Kubernetes releases 1.7.5

### 部署架构图

![安装架构](./attachments/k8s-deploy-arch.png)

说明：

- `Master` 为一台 host ，部署集群需要的服务
- `Node 1` , `Node 2`, `Node 3` 为 work 节点
- etcd
- flanneld 为 overlay 网络

| 节点 | IP |
|------|----|
| k8s-master | 10.0.0.123 |
| k8s-node-1 | 10.0.0.126 |
| k8s-node-2 | 10.0.0.128 |
| k8s-node-3 | 10.0.0.129 |

## 步骤

### Master

```
kubeadm init \
    --apiserver-advertise-address 10.0.0.123 \
    –-pod-network-cidr 10.244.0.0/16
```


#### `/proc/sys/net/bridge/bridge-nf-call-iptables`

错误详情：

```
[preflight] Some fatal errors occurred:
        /proc/sys/net/bridge/bridge-nf-call-iptables contents are not set to 1
[preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`
```

解决方法：

```
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.bridge.bridge-nf-call-ip6tables=1
```
