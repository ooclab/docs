# CentOS 7 安装 libvirt

## 参考

- [CentOS 初始化](../centos/initial.md)
- [CentOS Cloud Image](https://plus.ooclab.com/note/article/1391)
- [通过 iptables 完成端口转发](https://plus.ooclab.com/note/article/1408)

## 准备

下载 CentOS 7 Cloud Image :

```
wget https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1802.qcow2.xz
```

## 安装

```
yum install -y libvirt kvm qemu-kvm
```

## 创建第一个虚拟机

### 准备

启动 libvirtd 服务：

```
systemctl start libvirtd
```

查看当前虚拟机列表：

```
virsh list
```

创建目录 `/data/vos/centos/`，进入该目录：

```
mkdir -pv /data/vos/centos/
cd /data/vos/centos/
```

复制 `CentOS-7-x86_64-GenericCloud-1802.qcow2` 到该目录。

### 创建系统盘 `ooclab-dev.qcow2`

**ooclab-dev** :待创建的系统的标识,可根据实际场景修改。下面出现ooclab-dev一样，建议保持一致。

```
qemu-img create -b CentOS-7-x86_64-GenericCloud-1802.qcow2 -f qcow2 ooclab-dev.qcow2
```

### 创建 `config.iso`

创建 `user-data` :

```
#cloud-config

runcmd:
  - [ yum, -y, remove, cloud-init ]

output:
  all: ">> /var/log/cloud-init.log"

# 用户
users:
  - name: root
    # add ssh public keys
    ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2E...QfC4n03w== root@ooclab-t10
    - ssh-rsa AAAAB3NzaC...6IZQ== gwind@mbp

chpasswd:
  list: |
    root:ooclab
  expire: False

# configure interaction with ssh server
ssh_svcname: ssh
ssh_deletekeys: True
ssh_genkeytypes: ['rsa', 'ecdsa']
```
备注：
**ssh_authorized_keys** :登录用户的ssh public key.
**root:ooclab** ：登录的用户名和密码

创建 `meta-data` :

```
local-hostname: node01
```

创建 `config.iso` :

```
genisoimage -jcharset utf-8 -output config.iso -volid cidata -joliet -rock user-data meta-data
```

**注意** :

1. user-data 文件第一行必须是 `#cloud-config` ，一个其他字符不可以有（含空格）.

### 创建 `ooclab-dev.xml`

```xml
<domain type="kvm">
  <name>ooclab-dev</name>
  <os>
    <type arch="x86_64" machine="pc">hvm</type>
    <boot dev="hd"/>
  </os>
  <memory unit="MiB">4096</memory>
  <vcpu>4</vcpu>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset="localtime"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk device="disk" type="file">
      <target dev="vda" bus="virtio"/>
      <driver cache="none" io="threads" name="qemu" type="qcow2"/>
      <source file="/data/vos/centos/ooclab-dev.qcow2"/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/data/vos/centos/config.iso'/>
      <target dev='hdc' bus='ide'/>
      <readonly/>
    </disk>
    <interface type="network">
      <source network="default"/>
      <mac address="AC:DE:92:01:00:00"/>
      <model type='virtio' />
    </interface>
    <serial type="pty">
      <target port="0"/>
    </serial>
    <console type="pty">
      <target port="0" type="serial"/>
    </console>
    <input bus="usb" type="tablet"/>
    <graphics autoport="yes" keymap="en-us" listen="0.0.0.0" passwd="sailcraft" port="-1" type="spice"/>
    <video>
      <model type="qxl" vram="131072"/>
    </video>
    <sound model="ac97"/>
    <memballon model="virtio">
      <address bus="0x00" domain="0x0000" function="0x0" slot="0x05" type="pci"/>
    </memballon>
    <channel type="spicevmc">
      <target name="com.redhat.spice.0" type="virtio"/>
    </channel>
    <channel type="unix">
      <source mode="bind"/>
      <target name="org.qemu.guest_agent.0" type="virtio"/>
    </channel>
  </devices>
</domain>
```

备注：
  ```<source file="/data/vos/centos/ooclab-dev.qcow2"/>``` ：修改为对应的qcow2文件的地址
  ```<source file='/data/vos/centos/config.iso'/>``` ：修改为对应iso文件的地址



### 创建虚拟机

```
virsh create ooclab-dev.xml
```

### 使用

```
virsh console ooclab-dev
```

查看 IP , 通过另外的 ssh client 登录:

```
ssh -v centos@192.168.122.XXX
```

## Tips

### 创建 base 映像

如果需要将当前工作保存为一个 base image , 需要做些简单清理：

```
unalias rm
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
rm /etc/udev/rules.d/70*
rm ~/.bash_history
```

### 查看虚拟机 IP

#### 方法一

```
# virsh net-dhcp-leases default
 Expiry Time          MAC 地址         Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
 2018-04-28 21:52:08  ac:de:92:01:00:01  ipv4      192.168.122.232/24        -               -
 2018-04-28 21:44:31  ac:de:92:01:00:03  ipv4      192.168.122.234/24        -               -
```

#### 方法二

获取 IP 另外一个方式：

```
virsh qemu-agent-command ooclab-dev '{"execute":"guest-network-get-interfaces"}' | jq
```

## FAQ

### `failed to initialize KVM: Permission denied`

创建虚拟机出现错误：

```
[root@ooclab-t10 centos]# virsh create ooclab-dev.xml
错误：从 ooclab-dev.xml 创建域失败
错误：internal error: process exited while connecting to monitor:
(process:12948): GLib-WARNING **: gmem.c:483: custom memory allocation vtable not supported
Could not access KVM kernel module: Permission denied
failed to initialize KVM: Permission denied
```

请查看 `/dev/kvm` 权限：

```
[root@ooclab-t10 centos]# ls -l /dev/kvm
crw------- 1 root root 10, 232 4月  24 23:56 /dev/kvm
```

可以修改权限：

```
[root@ooclab-t10 centos]# chmod 660 /dev/kvm
[root@ooclab-t10 centos]# chown root.kvm /dev/kvm
```

不过最终我发现安装完 `qemu-kvm` 包即可解决该问题：

```
[root@ooclab-t10 centos]# ls -l /dev/kvm
crw-rw-rw- 1 root kvm 10, 232 4月  25 00:07 /dev/kvm
```
