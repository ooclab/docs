KONG_ADMIN=http://10.254.231.203:8001
UPSTREAM_PREFIX="http://s27-influxdb.powerp:8086"

api="s27-influxdb-api"

echo -e "\n--- ADD ${api}"
curl -X DELETE ${KONG_ADMIN}/apis/${api}
curl -X POST \
  --url ${KONG_ADMIN}/apis/ \
  --data "name=${api}" \
  --data "uris=/v1/s27" \
  --data "upstream_url=${UPSTREAM_PREFIX}/"
# log
curl -X POST ${KONG_ADMIN}/apis/${api}/plugins \
  --data "name=file-log" \
  --data "config.path=/tmp/kong-${api}.log"
# cors
curl -X POST ${KONG_ADMIN}/apis/${api}/plugins \
    --data "name=cors" \
    --data "config.origins=*" \
    --data "config.methods=GET, POST, DELETE, PUT, PATCH" \
    --data "config.headers=Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, Authorization, X-Auth-Token" \
    --data "config.exposed_headers=X-Auth-Token" \
    --data "config.credentials=true" \
    --data "config.max_age=3600"
