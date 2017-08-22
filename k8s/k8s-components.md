# k8s 组件

[Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)

介绍部署 k8s 所需的二进制组件


## Master 节点组件

Master 组件提供集群控制，通常集中运行在一台 VM 里即可。

[Building High-Availability Clusters](https://kubernetes.io/docs/admin/high-availability)

### kube-apiserver

kube-apiserver 提供 k8s API

### etcd

所有 k8s 集群自身的数据都存储在这里，请务必做好数据备份！

### kube-controller-manager

运行 controllers

### cloud-controller-manager

1.6 引入，运行底层云平台相关的 controllers

### kube-scheduler

为 Pod 选择 Node

### addons

附加组件以 pod 或 service 的形式，提供k8s集群更多特性。

#### DNS

k8s 集群通常都需要这个 addon

#### User Interface

kube-ui 提供一个只读集群状态信息

#### Container Resource Monitoring

提供一个基本的时序数据监控

#### Cluster-level Logging


## Node 节点组件

Node 组件运行在每一个节点上

### kubelet

kubelet 是主节点组件

### kube-proxy

通过在节点上执行网络规则，使 k8s 的 service 抽象得以实现

### docker

### rkt

### supervisord

### fluentd

集群日志中需要的 agent
