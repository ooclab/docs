# ElasticSearch

## 安装ElasticSearch
前往 https://hub.docker.com/_/elasticsearch/ 查询所要安装的elasticsearch相应版本的tag
此处使用最新版本

执行命令：

```
docker pull elasticsearch
```

使用docker 运行 elasticsearch 
(未经测试)

```
docker run -d elasticsearch
```


## 使用docker-compose

新建一个docker-compose.yml文件，增加以下内容：

```
version: '3.1'

services:

    elasticsearch:
        image: elasticsearch

    kibana:
        image: kibana
        ports:
            - 5601:5601

```

保存文件，使用docker-compose启动：

```
/usr/local/bin/docker-compose up -d 
```

执行命令测试：

```
# docker-compose ps 
           Name                         Command               State           Ports          
--------------------------------------------------------------------------------------------
datasearch_elasticsearch_1   /docker-entrypoint.sh elas ...   Up      9200/tcp, 9300/tcp     
datasearch_kibana_1          /docker-entrypoint.sh kibana     Up      0.0.0.0:5601->5601/tcp 
```

完美

## 参考

- [Install Docker ElasticSearch](https://hub.docker.com/_/elasticsearch/elasticsearch-kibana.md)
