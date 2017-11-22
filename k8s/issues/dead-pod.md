# 如何处理僵死 pod

部署多个 InfluxDB 实例到 k8s 集群，配置后端存储为 NFS 。
重启所有 InfluxDB 实例时，偶尔出现个别 InfluxDB 没有正确重启(通常是 httpd 8086 服务没有启动)，
进入该 pod 内，查看进程信息：

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  3.5  0.8 353936 60492 ?        Dsl  Nov21  43:48 influxd
```

`man ps` 可以查看 `STAT` 字段各字符含义

`D` 表示 `uninterruptible sleep (usually IO)` , 因此先猜测是由 NFS Server 挂载引起
