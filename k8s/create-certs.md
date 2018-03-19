# 创建 certs

## easyrsa

参考 [Certificates](https://kubernetes.io/docs/concepts/cluster-administration/certificates/)

### API Server

设定环境变量配置:

```
export MASTER_IP=172.16.17.103
export MASTER_CLUSTER_IP=10.254.0.1
```

下载 easy-rsa 并初始化 pki

```
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
./easyrsa init-pki
```

创建 CA

```
./easyrsa --batch "--req-cn=${MASTER_IP}@`date +%s`" build-ca nopass
```

创建 server 的密钥和证书

```
./easyrsa --subject-alt-name="IP:${MASTER_IP},"\
"IP:${MASTER_CLUSTER_IP},"\
"DNS:kubernetes,"\
"DNS:kubernetes.default,"\
"DNS:kubernetes.default.svc,"\
"DNS:kubernetes.default.svc.cluster,"\
"DNS:kubernetes.default.svc.cluster.local" \
--days=10000 \
build-server-full server nopass
```

**注意**
1. MASTER_CLUSTER_IP 通常为 `--service-cluster-ip-range=10.254.0.0/16` 参数指定的范围第一个IP
2. 假设 domain 为 `cluster.local`

生成的 `pki/ca.crt` , `pki/issued/server.crt` , `pki/private/server.key` 为 kube-apiserver 需要：

```
--client-ca-file=/yourdirectory/ca.crt
--tls-cert-file=/yourdirectory/server.crt
--tls-private-key-file=/yourdirectory/server.key
```
