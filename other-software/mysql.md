# mysql

## 安装mysql
前往 https://hub.docker.com/_/mysql/ 查询所要安装的mysql相应版本的tag
此处以 mysql 5.7 为例

执行命令：

```
docker pull mysql:5.7
```

运行 mysql

```
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:5.7
```
**注意** 将上面的 my-secrer-pw 修改为自己的密码 

## 使用docker-compose

新建一个docker-compose.yml文件，增加以下内容：

```
version: "3"
services:
  mysql:
    image: mysql:5.7
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: "example"

```
**注意** 将上面的 example 修改为自己的密码 

保存文件，使用docker-compose启动：

```
/usr/local/bin/docker-compose up -d 
```
**注意** 如果需要重命名services名称， 需要执行以下命令启动，否则提示报错：
````
docker-compose up -d  --remove-orphans
````
执行命令测试：

```
# docker-compose ps 
         Name                      Command             State           Ports          
-------------------------------------------------------------------------------------
dockercomponse_mysql_1   docker-entrypoint.sh mysqld   Up      0.0.0.0:3306->3306/tcp 
```

完美

## 参考

- [Install Docker Mysql](https://hub.docker.com/_/mysql/)
