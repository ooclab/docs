# 如何安装 Docker (最简单方法)

## 必备条件

1. 需要 Ubuntu/Debian/LinuxMint (等Deb) 或 CentOS/RedHat/Fedora (等RPM) 发行版的最新版
2. 示例使用 systemctl

## 安装 Docker

安装 docker

```
curl -fsSl https://get.docker.com | sh
```

增加当前用户访问权限（以 ooclab 用户名为例, root用户可跳过）

```
sudo usermod -aG docker ooclab
```

启动 docker

```
sudo systemctl start docker
```

设置自启动

```
sudo systemctl enable docker
```

使用中国镜像，创建 `/etc/docker/daemon.json` , 内容为

```
{
  "registry-mirrors": ["请找一个靠谱的国内镜像地址"]
}
```

重启 docker (如果后面立即重启系统，可以跳过这一步)

```
sudo systemctl restart docker
```

重启系统 `sudo reboot`


## 参考

加速器：

- [https://www.daocloud.io/mirror](https://www.daocloud.io/mirror) 最近偶尔行

最近使用这个方案加速比较正常：

- [Quay Proxy Cache 帮助](http://mirror.azk8s.cn/help/quay-proxy-cache.html)
