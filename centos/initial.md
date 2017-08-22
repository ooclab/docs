# CentOS 初始化

安装完 CentOS 系统常做的操作

## 更新系统

```
yum update -y
```

## 添加 epel 源

```
yum install -y epel-release
```

## 安装常见工具

```
yum install -y tmux vim dstat lsof htop tree jq rsync
```

- [Docker](../docker)
- [Docker Compose](../docker-compose)
