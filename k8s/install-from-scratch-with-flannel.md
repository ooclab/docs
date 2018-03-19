# 从零部署 Kubernetes (Flannel网络)

**注意** flannel 部署成功，但是不同 node 上的 POD IP ping 不同

## 参考

- [Creating a Custom Cluster from Scratch](https://kubernetes.io/docs/getting-started-guides/scratch/)
- https://github.com/kubernetes/dashboard/issues/1287#issuecomment-250681546
- https://www.kubernetes.org.cn/2270.html
- https://github.com/coreos/flannel/blob/master/Documentation/Kubernetes.md
- https://kubernetes.io/docs/concepts/cluster-administration/network-plugins
- https://www.centos.bz/2017/06/k8s-flannel-network/
- https://baijiahao.baidu.com/s?id=1571945107794880&wfr=spider&for=pc
- https://www.kubernetes.org.cn/2270.html


## 准备

- 2-4 台 host（物理机或虚拟机）
- 操作系统使用最新的 CentOS / Ubuntu x86_64
- Kubernetes releases 1.7.2

```
docker pull quay.io/coreos/flannel:v0.8.0-amd64
docker save quay.io/coreos/flannel:v0.8.0-amd64 > ~/flannel_v0.8.0-amd64.tar
docker load -i ~/flannel_v0.8.0-amd64.tar
```

### 部署架构图

![安装架构](./attachments/k8s-deploy-arch.png)

说明：

- `Master` 为一台 host ，部署集群需要的服务
- `Node 1` , `Node 2`, `Node 3` 为 work 节点
- etcd
- flanneld 为 overlay 网络

| 节点 | IP |
|------|----|
| k8s-master | 10.0.0.138 |
| k8s-node-1 | 10.0.0.123 |
| k8s-node-2 | 10.0.0.124 |
| k8s-node-3 | 10.0.0.125 |

## 步骤

### Master


#### Config & script

```
floreks@floreks-MS-7916:~/kubernetes$ cat worker-openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 192.168.0.101

floreks@floreks-MS-7916:~/kubernetes$ cat openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.0.0.1
IP.2 = 10.0.0.138
```

```
floreks@floreks-MS-7916:~/kubernetes$ cat generate-certs.sh
#!/bin/bash

# Generate CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -days 365 -out ca.crt -subj "/CN=kube-ca"

# Generate api server
openssl genrsa -out apiserver.key 2048
openssl req -new -key apiserver.key -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver.crt -days 365 -extensions v3_req -extfile openssl.cnf

# Generate kubelet
openssl genrsa -out kubelet.key 2048
openssl req -new -key kubelet.key -out kubelet.csr -subj "/CN=kubelet" -config worker-openssl.cnf
openssl x509 -req -in kubelet.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kubelet.crt -days 365 -extensions v3_req -extfile worker-openssl.cnf

# Generate admin
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 365
```

#### etcd

安装 etcd ：

    yum install -y etcd

编辑 `/etc/etcd/etcd.conf` , 修改 ：

    ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"

重启 etcd ：

    systemctl restart etcd


#### kube-apiserver

```
kube-apiserver \
    --bind-address=0.0.0.0 \
    --secure-port=443 \
    --etcd-servers=http://10.0.0.138:2379  \
    --service-cluster-ip-range=10.254.0.0/16 \
    --allow-privileged \
    --advertise-address 10.0.0.138 \
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota \
    --tls-cert-file ~/config/certs/apiserver.crt \
    --tls-private-key-file ~/config/certs/apiserver.key \
    --client-ca-file ~/config/certs/ca.crt \
    --service-account-key-file ~/config/certs/apiserver.key
```

#### kube-scheduler

```
kube-scheduler --kubeconfig ~/config/var_lib_kubelet/kubeconfig
```

#### kube-controller-manager

```
kube-controller-manager \
    --kubeconfig ~/config/var_lib_kubelet/kubeconfig \
    --service-account-private-key-file ~/config/certs/apiserver.key \
    --root-ca-file ~/config/certs/ca.crt \
    --allocate-node-cidrs=true --cluster-cidr=10.244.0.0/16
```


### Node

以 k8s-node-1 为例

#### kubelet

创建 `kubeconfig` 配置文件：

```
kubectl config set-cluster kubernetes \
    --server=http://192.168.122.58:8080 \
    --kubeconfig=kubeconfig
# 设置上下文参数
kubectl config set-context default \
    --cluster=kubernetes \
    --user=kubelet \
    --kubeconfig=kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kubeconfig
```

生成的 `kubeconfig` 配置文件如下：

```yaml
apiVersion: v1
clusters:
- cluster:
    server: http://192.168.122.58:8080
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: default
current-context: default
kind: Config
preferences: {}
users: []
```

启动 kubelet :

```
kubelet \
    --require-kubeconfig \
    --kubeconfig=/root/config/var_lib_kubelet/kubeconfig \
    --pod-infra-container-image=ibmcom/pause:3.0 \
    --network-plugin=cni \
    --allow-privileged
```

**注意** 默认路径 `/var/lib/kubelet/kubeconfig`

`cat /var/lib/kubelet/kubeconfig`

```yaml
current-context: default-context
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /root/certs/ca.crt
    server: https://10.0.0.122
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: admin
  name: default-context
- context:
kind: Config
preferences: {}
users:
- name: admin
  user:
    client-certificate: /root/certs/admin.crt
    client-key: /root/certs/admin.key
```

#### kube-proxy

```
kube-proxy --kubeconfig /root/config/var_lib_kubelet/kubeconfig --proxy-mode=iptables
```

`kube-proxy --kubeconfig /var/lib/kubelet/kubeconfig --proxy-mode=iptables`

#### 问题

##### pause 映像替换

https://hub.docker.com/r/ibmcom/pause/

```
--pod-infra-container-image=ibmcom/pause:3.0
```


## 模块说明

### Flannel

- https://github.com/coreos/flannel/blob/master/Documentation/troubleshooting.md

```
kubectl apply -f  kube-flannel.yml
```

查看:

```
kubectl get ds --all-namespaces -o wide
```

查看详细描述：

```
kubectl describe ds kube-flannel-ds --namespace kube-system
```

**注意** flannel cni 插件安装(所有kubelet node都需要安装)

```
# cd
# wget https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz
# mkdir -pv /opt/cni/bin
# cd /opt/cni/bin
# tar xf ~/cni-plugins-amd64-v0.6.0.tgz
```


#### 错误

##### `spec.template.spec.containers[0].securityContext.privileged`

```
The DaemonSet "kube-flannel-ds" is invalid: spec.template.spec.containers[0].securityContext.privileged: Forbidden: disallowed by cluster policy
```

以 `--allow-privileged` 启动　kubelet, kube-apiserver

##### `failed to get default interface`

查看node上的flannel容器退出错误信息：

```
failed to get default interface: Unable to find default route
```

##### `/var/run/secrets/kubernetes.io/serviceaccount/token`

```
Failed to create SubnetManager: unable to initialize inclusterconfig: open /var/run/secrets/kubernetes.io/serviceaccount/token: no such file or directory
```

```
No API token found for service account "flannel"
```

```
Failed to create SubnetManager: error retrieving pod spec for 'kube-system/kube-flannel-ds-01kcn': Get https://10.254.0.1:443/api/v1/namespaces/kube-system/pods/kube-flan
nel-ds-01kcn: dial tcp 10.254.0.1:443: getsockopt: no route to host
```

```
iptables -t nat -A PREROUTING -d 10.254.0.1 -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1
```

```
Expected to load root CA config from /var/run/secrets/kubernetes.io/serviceaccount/ca.crt, but got err: open /var/run/secrets/kubernetes.io/serviceaccount/ca.crt: no such file or directory
```

```
Failed to create SubnetManager: error retrieving pod spec for 'kube-system/kube-flannel-ds-01kcn': Get https://10.254.0.1:443/api/v1/namespaces/kube-system/pods/kube-flannel-ds-01kcn: x509: failed to load system roots and no roots provided
```

```
Failed to create SubnetManager: error retrieving pod spec for 'kube-system/kube-flannel-ds-01kcn': the server has asked for the client to provide credentials (get pods kube-flannel-ds-01kcn)
```

```
Error registering network: failed to acquire lease: node "k8s-node-3" pod cidr not assigned
```

- https://github.com/coreos/flannel/issues/728

kube-controller-manager增加选项:

```
--allocate-node-cidrs=true --cluster-cidr=10.244.0.0/16
```

## Tips

### 查看日志

```
kubectl -n kube-system logs -c kube-flannel kube-flannel-ds-gc076
```

## 重置

集群创建过程中出现问题，可以重置环境

### etcd

```
systemctl stop etcd
rm -rf /var/lib/etcd/
mkdir -pv /var/lib/etcd/
chown -R etcd.etcd /var/lib/etcd/
systemctl start etcd
```

## 参考

- [Battlefield: Calico, Flannel, Weave and Docker Overlay Network](http://chunqi.li/2015/11/15/Battlefield-Calico-Flannel-Weave-and-Docker-Overlay-Network/)
