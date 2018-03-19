# Calico FAQ

## 指定 etcd 地址

- https://docs.projectcalico.org/v1.5/reference/advanced/etcd-secure

```
[root@k8s-master ~]# export ETCD_AUTHORITY=10.0.0.7:2379                                                  
[root@k8s-master ~]# calicoctl get node -o wide                                                         
NAME         ASN       IPV4          IPV6   
k8s-master   (64512)   10.0.0.7/24          
k8s-node-1   (64512)   10.0.0.8/24
```


## 没有路由

正常情况下 calico node 会自动添加路由到其他 node 。
例如，我有 `k8s-node-1 (10.0.0.123)` , `k8s-node-2 (10.0.0.124)` ,
`k8s-node-3 (10.0.0.125)` 三个 calico node , 在 k8s-node-1 节点查看其路由：

```
# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.0.1        0.0.0.0         UG    0      0        0 eth0
10.0.0.0        0.0.0.0         255.0.0.0       U     0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.76.128  0.0.0.0         255.255.255.192 U     0      0        0 *
192.168.76.130  0.0.0.0         255.255.255.255 UH    0      0        0 cali23380d3eede
192.168.76.131  0.0.0.0         255.255.255.255 UH    0      0        0 calid75b7a339ff
192.168.76.133  0.0.0.0         255.255.255.255 UH    0      0        0 cali475b7384bc5
192.168.76.134  0.0.0.0         255.255.255.255 UH    0      0        0 calid54905ac577
192.168.76.136  0.0.0.0         255.255.255.255 UH    0      0        0 calidf14eaaaa33
192.168.109.64  10.0.0.123      255.255.255.192 UG    0      0        0 tunl0
192.168.140.64  10.0.0.124      255.255.255.192 UG    0      0        0 tunl0
```

其中 `tunl0` 相关的2条记录为到其他 node 的路由

使用 calicoctl 查看信息：

```
# calicoctl node status
Calico process is running.

IPv4 BGP status
+--------------+-------------------+-------+------------+-------------+
| PEER ADDRESS |     PEER TYPE     | STATE |   SINCE    |    INFO     |
+--------------+-------------------+-------+------------+-------------+
| 10.0.0.123   | node-to-node mesh | up    | 2017-09-08 | Established |
| 10.0.0.124   | node-to-node mesh | up    | 2017-09-08 | Established |
+--------------+-------------------+-------+------------+-------------+

IPv6 BGP status
No IPv6 peers found.
```

一切正常！

但我在 azure 上部署的2个节点集群 ( `k8s-master (10.0.0.7)` , `k8s-node-1 (10.0.0.8)` ,
其中 k8s-master 也作为 k8s node 角色) 。

部署 calico 后，两个节点间没有自动创建 tunl0 的路由( `calico-policy-controller` 被自动分配在 k8s-master 上 )

`k8s-master` 查看状态(正常):

```
# calicoctl node status
Calico process is running.

IPv4 BGP status
+--------------+-------------------+-------+----------+--------------------------------+
| PEER ADDRESS |     PEER TYPE     | STATE |  SINCE   |              INFO              |
+--------------+-------------------+-------+----------+--------------------------------+
| 10.0.0.8     | node-to-node mesh | start | 13:05:33 | Active Socket: Connection      |
|              |                   |       |          | reset by peer                  |
+--------------+-------------------+-------+----------+--------------------------------+

IPv6 BGP status
No IPv6 peers found.
```

`k8s-node-1` 查看状态(错误):

```
# calicoctl node status
Calico process is running.

IPv4 BGP status
+--------------+-------------------+-------+----------+---------+
| PEER ADDRESS |     PEER TYPE     | STATE |  SINCE   |  INFO   |
+--------------+-------------------+-------+----------+---------+
| 172.18.0.1   | node-to-node mesh | start | 13:05:33 | Connect |
+--------------+-------------------+-------+----------+---------+

IPv6 BGP status
No IPv6 peers found.
```

`172.18.0.1` 是 `k8s-master` 上一个网卡，应该是 `10.0.0.7` 才正确

原因是我在 k8s-master 使用 docker-compose 启动了 master 相关服务，其中使用了一个网络，因此多出这个网卡。
使用 `host` 网络就不会创建这个虚拟网卡。

参考：

- [Not creating route for tunl0](https://github.com/projectcalico/cni-plugin/issues/314)
- [Configuring calico/node](https://docs.projectcalico.org/master/reference/node/configuration)
