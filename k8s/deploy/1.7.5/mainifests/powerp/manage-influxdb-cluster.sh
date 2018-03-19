#! /bin/bash

# $1是 create 或者 delete

# cat <<EOF | kubectl $1 -f -
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: powerp
# EOF


STATIONS="392 340 76 77 75 79 78 27 59 80 53 51 73 60 350 394 56 302 402 403 406 74 404 407 360 393 83 380 401 502"
for station in $STATIONS; do
    cat <<EOF | kubectl $1 -f -
---
apiVersion: v1
kind: Service
metadata:
  name: s${station}-influxdb
  namespace: powerp
spec:
  selector:
    role: s${station}-influxdb
  ports:
  - port: 8086
    targetPort: 8086

---
apiVersion: v1
kind: ReplicationController
metadata:
  name: s${station}-influxdb
  namespace: powerp
spec:
  replicas: 1
  template:
    metadata:
      labels:
        role: s${station}-influxdb
    spec:
      containers:
      - name: influxdb
        image: influxdb
        imagePullPolicy: Always
        ports:
          - containerPort: 8086
        volumeMounts:
          - mountPath: /var/lib/influxdb
            name: s${station}-data
      volumes:
        - name: s${station}-data
          hostPath:
            path: /data/product/powerp/influxdb/s${station}
EOF
done
