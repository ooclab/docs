# KVM 嵌套虚拟化

## 参考

- [How to enable nested virtualization in KVM](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/index.html)
- [Nested Guests](https://www.linux-kvm.org/page/Nested_Guests)
- [How to enable Nested Virtualization in KVM on CentOS 7 / RHEL 7](https://www.linuxtechi.com/enable-nested-virtualization-kvm-centos-7-rhel-7/)

## 开启 KVM 嵌套虚拟化支持

如果使用 libvirtd 管理 KVM 实例，请先停止运行 libvirtd ，再执行下列操作。

```
echo 'options kvm-intel nested=1' > /etc/modprobe.d/kvm.conf
modprobe -r kvm_intel
modprobe kvm_intel
```

检查 `/sys/module/kvm_intel/parameters/nested` 是否为 `Y` , 即为支持 KVM 嵌套虚拟化。

```
# cat /sys/module/kvm_intel/parameters/nested
Y
```

## libvirt 配置

在 Domain XML 定义文件中，添加：

```
<cpu mode="host-model" check="partial">
  <model fallback="allow"/>
</cpu>
```

示例：
```
<domain type="kvm">
  <name>gwind-test</name>
  <os>
    <type arch="x86_64" machine="pc">hvm</type>
    <boot dev="hd"/>
  </os>
  <memory unit="MiB">2048</memory>
  <vcpu>1</vcpu>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode="host-model" check="partial">
    <model fallback="allow"/>
  </cpu>
  <clock offset="localtime"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  ...
</domain>
```
