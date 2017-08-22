# kubectl 管理 kubernetes 集群

## Tips

### 重启 POD

如果有源配置文件：

```
kubectl replace --force -f <resource-file>
```

如果没有源配置文件：

```
kubectl get pod PODNAME -n NAMESPACE -o yaml | kubectl replace --force -f -
```
