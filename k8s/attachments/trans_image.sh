#! /bin/bash

# https://hub.docker.com
# 第一次运行需要执行 `docker login` 验证帐户

# 将指定的 image 转移到 hub.docker.com 上
# 使用 omio 组织名称

# https://hub.docker.com/u/omio/dashboard/
ORG=omio

# gcr.io/google_containers/pause-amd64:3.0 -> $ORG/gcr.io.google_containers.pause-amd64:3.0
function trans() {
    ORIG_NAME=$1
    NEW_NAME=`echo ${ORIG_NAME} | sed 's@/@.@g'`

    docker pull $ORIG_NAME
    docker tag $ORIG_NAME $ORG/$NEW_NAME
    docker push $ORG/$NEW_NAME
}

for var in "$@"
do
    echo "==> $var"
    trans $var
done
