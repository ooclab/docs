# 部署 k8s 案例

## flannel

```
etcdctl set /coreos.com/network/config < flannel-config.json
```

如果 pod 之间不能 ping 通

```
iptables -P FORWARD ACCEPT
```

- https://github.com/coreos/flannel/issues/609
- https://github.com/moby/moby/pull/28257
- [docker 1.13+ FORWARD链为DROP的问题](http://zhaodaxin.com/2017/03/16/docker1.13+版本FORWARD链为DROP的问题/)

## clean

master:

```
systemctl stop etcd
rm -rf /var/lib/etcd/
mkdir -pv /var/lib/etcd/
chown etcd.etcd /var/lib/etcd/
```

node:

```
systemctl stop docker
rm -rf /opt/cni/ /etc/cni/ /run/calico/
```

```
systemctl stop docker
rm -rf /var/run/docker/ /var/lib/docker
ip link del docker0
```

## Master

### etcd

### apiserver

```
/opt/k8s/master/bin/kube-apiserver \
    --bind-address=0.0.0.0 \
    --secure-port=443 \
    --etcd-servers=http://10.0.0.7:2379 \
    --service-cluster-ip-range=10.254.0.0/16 \
    --allow-privileged \
    --advertise-address 10.0.0.7 \
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota \
    --tls-cert-file /opt/k8s/master/certs/apiserver.crt \
    --tls-private-key-file /opt/k8s/master/certs/apiserver.key \
    --client-ca-file /opt/k8s/master/certs/ca.crt \
    --service-account-key-file /opt/k8s/master/certs/apiserver.key
```

### scheduler

```
/opt/k8s/master/bin/kube-scheduler --kubeconfig /opt/k8s/master/conf/kubeconfig
```

### controller-manager

```
/opt/k8s/master/bin/kube-controller-manager \
    --kubeconfig /opt/k8s/master/conf/kubeconfig \
    --service-account-private-key-file /opt/k8s/master/certs/apiserver.key \
    --root-ca-file /opt/k8s/master/certs/ca.crt
```

## Node

### kubelet

```
/opt/k8s/node/bin/kubelet \
    --require-kubeconfig \
    --kubeconfig=/opt/k8s/node/conf/kubeconfig \
    --pod-infra-container-image=omio/gcr.io.google_containers.pause-amd64:3.0 \
    --network-plugin=cni --allow-privileged
```

部署好 kube-dns 后，可能需要添加：

```
--cluster-dns=10.254.1.1 --cluster-domain=ooclab.io
```

### kube-proxy

```
/opt/k8s/node/bin/kube-proxy --kubeconfig /opt/k8s/node/conf/kubeconfig --proxy-mode=iptables
```


## 参考

- [Creating a Custom Cluster from Scratch](https://kubernetes.io/docs/getting-started-guides/scratch/)


## 准备

- 2-4 台 host（物理机或虚拟机）
- 操作系统使用最新的 CentOS / Ubuntu x86_64
- Kubernetes releases 1.7.5

### 部署架构

说明：

- `Master` 为一台 host ，部署集群需要的服务
- `Node 1` , `Node 2`, `Node 3` 为 work 节点
- etcd
- Calico 网络

| 节点 | IP |
|------|----|
| k8s-master | 10.0.0.138 |
| k8s-node-1 | 10.0.0.123 |
| k8s-node-2 | 10.0.0.124 |
| k8s-node-3 | 10.0.0.125 |

### GFW

以

```
# docker load -i kube-apiserver.tar
6a749002dd6a: Loading layer [==================================================>]  1.338MB/1.338MB
03969ac1c024: Loading layer [==================================================>]    185MB/185MB
Loaded image: gcr.io/google_containers/kube-apiserver:v1.7.5
# docker tag gcr.io/google_containers/kube-apiserver:v1.7.5 ooclab/k8s.kube-apiserver:v1.7.5
# docker push ooclab/k8s.kube-apiserver:v1.7.5
```

```sh
# pause
gcr.io/google_containers/pause-amd64:3.0
# kube-dns
gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.4
gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4
# dashboard
gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3
# heapster
gcr.io/google_containers/heapster-amd64:v1.4.2
```



## 步骤

### 准备

#### Config & script

`worker-openssl.cnf` 内容如下

```
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 10.0.0.124
```

`openssl.cnf` 内容如下

```
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
IP.3 = 10.254.0.1
```

`generate-certs.sh` 内容如下

```sh
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

执行 `generate-certs.sh` , 生成相关文件


### Master

#### etcd

安装 etcd ：

    yum install -y etcd

编辑 `/etc/etcd/etcd.conf` , 修改 ：

    ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"

重启 etcd ：

    systemctl restart etcd


https://coreos.com/etcd/docs/latest/op-guide/container.html

```
export NODE1=10.0.0.138
export DATA_DIR=/data/product/etcd
docker run --rm --net=host \
  --volume=${DATA_DIR}:/etcd-data \
  --name etcd quay.io/coreos/etcd:latest \
  /usr/local/bin/etcd \
  --data-dir=/etcd-data --name node1 \
  --initial-advertise-peer-urls http://${NODE1}:2380 --listen-peer-urls http://${NODE1}:2380 \
  --advertise-client-urls http://${NODE1}:2379 --listen-client-urls http://${NODE1}:2379 \
  --initial-cluster node1=http://${NODE1}:2380
```

查看 member list

```
# etcdctl --endpoints=http://10.0.0.138:2379 member list                                                                                                                                          
65e3707f9a633ce5: name=node1 peerURLs=http://10.0.0.138:2380 clientURLs=http://10.0.0.138:2379 isLeader=true
```


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

```
docker run -it --rm --net=host \
    -v ~/deploy/certs:/certs \
    ooclab/k8s.kube-apiserver:v1.7.5 kube-apiserver \
    --bind-address=0.0.0.0 \
    --secure-port=443 \
    --etcd-servers=http://10.0.0.138:2379  \
    --service-cluster-ip-range=10.254.0.0/16 \
    --allow-privileged \
    --advertise-address 10.0.0.138 \
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota \
    --tls-cert-file /certs/apiserver.crt \
    --tls-private-key-file /certs/apiserver.key \
    --client-ca-file /certs/ca.crt \
    --service-account-key-file /certs/apiserver.key
```


#### kube-scheduler

```
kube-scheduler --kubeconfig ~/config/var_lib_kubelet/kubeconfig
```

```
docker run -it --rm --net=host \
    -v ~/deploy/certs:/certs \
    -v ~/deploy/config/kubeconfig:/kubeconfig \
    ooclab/k8s.kube-scheduler:v1.7.5 kube-scheduler \
    --kubeconfig=/kubeconfig
```


#### kube-controller-manager

```
kube-controller-manager \
    --kubeconfig ~/config/var_lib_kubelet/kubeconfig \
    --service-account-private-key-file ~/config/certs/apiserver.key \
    --root-ca-file ~/config/certs/ca.crt \
    --allocate-node-cidrs=true --cluster-cidr=10.244.0.0/16
```

```
docker run -it --rm --net=host \
    -v ~/deploy/certs:/certs \
    -v ~/deploy/config/kubeconfig:/kubeconfig \
    ooclab/k8s.kube-controller-manager:v1.7.5 kube-controller-manager \
    --kubeconfig=/kubeconfig \
    --service-account-private-key-file /certs/apiserver.key \
    --root-ca-file /certs/ca.crt
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
    --kubeconfig=/opt/k8s/node/conf/kubeconfig \
    --pod-infra-container-image=omio/gcr.io.google_containers.pause-amd64:3.0 \
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
kube-proxy --kubeconfig /opt/k8s/node/conf/kubeconfig --proxy-mode=iptables
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

##### kube-proxy `exec: "conntrack": executable file not found in $PATH`

```
yum install conntrack -y
```

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
