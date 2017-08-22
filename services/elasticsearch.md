# Elasticsearch

Elasticsearch 现在发展的不错，目前 images 已经不放在 hub.docker.com 上，官方自己托管。
容器部署的配置也变得复杂了一点，但是这显得更加符合生产环境要求。

参考：

- [Install Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)

## 简单示例

```yaml
version: '3'
services:
  myes:
    image: docker.elastic.co/elasticsearch/elasticsearch:5.5.2
    environment:
      - cluster.name=myeshost
      - "ES_JAVA_OPTS=-Xms256m -Xmx256m"
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - /data/product/es/data:/usr/share/elasticsearch/data
```

打开 [http://127.0.0.1:9200](http://127.0.0.1:9200) , 输入用户名 elastic , 密码 changeme 可以查看信息。

### 说明

#### elasticsearch 挂载的数据目录需要修改权限

es 容器里默认使用　elasticsearch 用户(UID:1000, GID: 1000)权限运行程序，因此外部关在的 volumes 需要可写权限。

```
# mkdir -pv /data/product/es/
# chown -R 1000.1000 /data/product/es/
```

#### 用户名及密码

默认状态， `X-Pack` 已经内置在容器中，因此需要严重。默认的用户名　elastic 密码是 changeme
