# CentOS 7 环境部署实践

## 环境

阿里云环境, CentOS 7, kubernetes 1.7.2

## 架构

- Master: inet 10.31.166.39  netmask 255.255.252.0
- Node1:

## Master

### etcd

修改 `/etc/etcd/etcd.conf`:

```
ETCD_LISTEN_CLIENT_URLS="http://10.31.166.39:2379"
```

### flannel

创建 `flannel-config.json` 文件：

```json
{
  "Network": "10.20.0.0/16",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan",
    "VNI": 1
  }
}
```

写入 etcd :

```
# etcdctl --no-sync --endpoints "http://10.31.166.39:2379" set /atomic.io/network/config < flannel-config.json                                                                                       
{
  "Network": "10.20.0.0/16",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan",
    "VNI": 1
  }
}
```
