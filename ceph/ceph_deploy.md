# ceph 部署

* 参考 
 1. [Preflight Checklist](http://docs.ceph.com/docs/master/start/quick-start-preflight/#ceph-deploy-setup)
 2. [Storage Cluster Quick Start](http://docs.ceph.com/docs/master/start/quick-ceph-deploy/)

* 规划图

![](http://docs.ceph.com/docs/master/_images/ditaa-4064c49b1999d81268f1a06e419171c5e44ab9cc.png)

* 节点情况

```
192.168.122.196 deploy
192.168.122.149 node1
192.168.122.18 node2
192.168.122.35 node3
```

*各节点的系统为：centos7.4 minimal*

## 预先准备

### ceph yum 源设定

```
vim /etc/yum.repo.d/ceph.repo
```

```
[Ceph]
name=Ceph packages for $basearch
baseurl=http://download.ceph.com/rpm-jewel/el7/$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
priority=1

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://download.ceph.com/rpm-jewel/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
priority=1

[ceph-source]
name=Ceph source packages
baseurl=http://download.ceph.com/rpm-jewel/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
priority=1
```

### SSH 免密登录

从 deploy 节点向 node1、node2、node3 节点做 ssh 认证

```
ssh-keygen
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3
```

## 防火墙和 SELINUX 设定

### 防火墙设定

```
systemctl stop firewalld
systemctl disable firewalld
```

### SELINUX 设定

```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
reboot
```

### 配置 NTP 

**说明：** 我们以部署节点来做 ntp-server，其他的节点来向 deploy 节点进行同步

* 在 deploy 节点上：

```
yum install ntp
vim /etc/ntp.conf
```

```
server 0.cn.pool.ntp.org
server 1.cn.pool.ntp.org
server 2.cn.pool.ntp.org
server 3.cn.pool.ntp.org


restrict 0.cn.pool.ntp.org nomodify notrap noquery
restrict 1.cn.pool.ntp.org nomodify notrap noquery
restrict 2.cn.pool.ntp.org nomodify notrap noquery
restrict 3.cn.pool.ntp.org nomodify notrap noquery

server 127.0.0.1 # local clock
fudge 127.0.0.1 stratum 10
```

* 在 node 节点上

```
yum install ntp -y
vim /etc/ntp.conf
```

>server deploy

## 部署 ceph

*以下操作在 deploy 节点上进行。*

```
yum install ceph-deploy
mkdir cluster
cd clutser
ceph-deploy new node1
vim ceph.conf
```

>public network = 192.168.122.0/24

```
ceph-deploy install node1 node2 node3
ceph-deploy mon create-initial
ceph-deploy admin node1 node2 node3
ceph-deploy osd create node1:vdb node2:vdb node3:vdb
```

## 测试

*以下操作是在 node1 节点进行。*

### 查看集群状态

```
ceph -s
```

### 设定集群默认的副本数为 2

```
ceph osd pool set poolname size 2
ceph osd pool set poolname min_size 1
```

### ceph 的性能测试

#### rados 性能测试

```
rados bench -p rbd 10 write --no-cleanup
```

```
[root@node1 ~]# rados bench -p rbd 10 write --no-cleanup
Maintaining 16 concurrent writes of 4194304 bytes to objects of size 4194304 for up to 10 seconds or 0 objects
Object prefix: benchmark_data_node1_6143
 sec Cur ops   started  finished  avg MB/s  cur MB/s last lat(s)  avg lat(s)
   0       0         0         0         0         0           -           0
   1      16        27        11   43.9897        44    0.158622    0.132078
   2      16        27        11   21.9946         0           -    0.132078
   3      16        27        11   14.6632         0           -    0.132078
   4      16        27        11   10.9974         0           -    0.132078
   5      16        29        13   10.3975         2     4.48653    0.801245
   6      16        33        17   11.3307        16     5.83552     1.98999
   7      16        33        17   9.71202         0           -     1.98999
   8      16        33        17     8.498         0           -     1.98999
   9      16        43        27   11.9972   13.3333     8.38729     4.36487
  10      16        43        27   10.7975         0           -     4.36487
  11      16        43        27   9.81593         0           -     4.36487
  12      16        43        27   8.99793         0           -     4.36487
  13      16        43        27   8.30579         0           -     4.36487
  14      16        43        27   7.71251         0           -     4.36487
  15      16        44        28   7.46495  0.666667     10.2601     4.57541
  16      16        44        28   6.99839         0           -     4.57541
  17      15        44        29   6.82196         2      10.148     4.76757
  18      15        44        29   6.44294         0           -     4.76757
  19      15        44        29   6.10384         0           -     4.76757
2017-12-05 16:21:42.700892 min lat: 0.102313 max lat: 10.2601 avg lat: 4.76757
 sec Cur ops   started  finished  avg MB/s  cur MB/s last lat(s)  avg lat(s)
  20      15        44        29   5.79865         0           -     4.76757
Total time run:         20.331496
Total writes made:      44
Write size:             4194304
Object size:            4194304
Bandwidth (MB/sec):     8.65652
Stddev Bandwidth:       10.4479
Max bandwidth (MB/sec): 44
Min bandwidth (MB/sec): 0
Average IOPS:           2
Stddev IOPS:            2
Max IOPS:               11
Min IOPS:               0
Average Latency(s):     7.29053
Stddev Latency(s):      4.9346
Max latency(s):         15.843
Min latency(s):         0.102313
```

#### rbd 块设备性能测试

```
rbd create bd0 --size 10G --image-format 2 --image-feature layering
rbd map bd0
rbd showmapped
mkfs.xfs /dev/rbd0
mkdir -p /mnt/ceph-bd0
mount /dev/rbd0 /mnt/ceph-bd0/
rbd bench-write bd2 --io-total 171997300
```

```
[root@node1 ~]# rbd bench-write bd2 --io-total 171997300
bench-write  io_size 4096 io_threads 16 bytes 171997300 pattern sequential
  SEC       OPS   OPS/SEC   BYTES/SEC
    3     16403   4565.67  18700991.63
    5     16732   3025.63  12392968.92
    6     16780   2506.66  10267282.10
    7     17316   2464.75  10095624.00
    9     20506   2275.66  9321092.65
   10     21019    705.50  2889722.18
   12     32463   2183.37  8943067.81
   13     33340   2525.23  10343326.56
   16     39702   2340.36  9586124.18
   19     39889   1934.44  7923454.07
   26     40046   1193.27  4887622.33
   28     40393    496.41  2033296.68
   29     40953    483.60  1980809.31
elapsed:    29  ops:    41992  ops/sec:  1443.13  bytes/sec: 5911064.21
```
