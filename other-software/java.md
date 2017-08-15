# JAVA

## 安装java JDK
前往 https://hub.docker.com/_/java/ 查询所要安装的java相应版本的tag
此处以 java 8 为例

执行命令：

```
docker pull java:8
```

不需要运行，在自己的java项目的dockerfile中增加 
``FROM java:8``
即可。


## 使用docker-compose

不会


## 参考

- [Install Docker JAVA](https://hub.docker.com/_/java/)
