# 安装 docker-compose

前往 https://github.com/docker/compose/releases 下载最新的 docker-compose

命令行示例（以 1.14.0 为例）：

```
curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

**注意** 由于 github 使用某个国内不方便访问的资源，上面命令国内通常是无法工作的。国内用户请使用代理下载。比如我下载的 `docker-compose-Linux-x86_64`：

```
sudo mv ~/下载/docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
```

增加可执行权限：

```
chmod a+x /usr/local/bin/docker-compose
```

测试并查看版本号：

```
$ docker-compose version
docker-compose version 1.14.0, build c7bdf9e
docker-py version: 2.3.0
CPython version: 2.7.13
OpenSSL version: OpenSSL 1.0.1t  3 May 2016
```

## 参考

- [Install Docker Compose](https://docs.docker.com/compose/install/)
