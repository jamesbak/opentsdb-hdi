#!/bin/bash          

# Script run nohup on the active head node only to provision & deploy OpenTSDB services via Ambari

user=$1
password=$2
cluster=$3

# Ambari has just had a new service installed & has been restarted. We have to wait for it to come back up properly 
sleep 60s

echo "Processing service registration on active head node"
su - ams -c'/usr/sbin/ambari-metrics-collector --config /etc/ambari-metrics-collector/conf/ restart'

curl -u $user:$password -H "X-Requested-By:ambari" -X POST -d '{"ServiceInfo":{"service_name":"OPENTSDB"}}' "http://headnodehost:8080/api/v1/clusters/$cluster/services"
curl -u $user:$password -H "X-Requested-By:ambari" -X POST "http://headnodehost:8080/api/v1/clusters/$cluster/services/OPENTSDB/components/OPENTSDB_TSD"
curl -u $user:$password -H "X-Requested-By:ambari" -X POST "http://headnodehost:8080/api/v1/clusters/$cluster/services/OPENTSDB/components/OPENTSDB_PROXY"
config_tag=INITIAL
curl -u $user:$password -H "X-Requested-By:ambari" -X POST -d '{"type": "opentsdb-site", "tag": "'$config_tag'", "properties" : {
        "tsd.core.auto_create_metrics" : "true",
        "tsd.http.cachedir" : "/tmp/opentsdb",
        "tsd.http.staticroot" : "/usr/share/opentsdb/static/",
        "tsd.network.async_io" : "true",
        "tsd.network.keep_alive" : "true",
        "tsd.network.port" : "4242",
        "tsd.network.reuse_address" : "true",
        "tsd.network.tcp_no_delay" : "true",
        "tsd.storage.enable_compaction" : "true",
        "tsd.storage.flush_interval" : "1000",
        "tsd.storage.hbase.data_table" : "tsdb",
        "tsd.storage.hbase.uid_table" : "tsdb-uid"
    }}' "http://headnodehost:8080/api/v1/clusters/$cluster/configurations"
curl -u $user:$password -H "X-Requested-By:ambari" -X POST -d '{"type": "opentsdb-config", "tag": "'$config_tag'", "properties" : {
        "opentsdb.create_schema" : "true",
        "opentsdb.opentsdb_version" : "2.2.0"
    }}' "http://headnodehost:8080/api/v1/clusters/$cluster/configurations"
curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"Clusters":{"desired_config" : {"type": "opentsdb-site", "tag": "'$config_tag'"}}}' "http://headnodehost:8080/api/v1/clusters/$cluster"
curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"Clusters":{"desired_config" : {"type": "opentsdb-config", "tag": "'$config_tag'"}}}' "http://headnodehost:8080/api/v1/clusters/$cluster"

# deploy to all Region Server nodes
region_hosts=$(curl -u $user:$password -H "X-Requested-By:ambari" "http://headnodehost:8080/api/v1/clusters/$cluster/services/HBASE/components/HBASE_REGIONSERVER?fields=host_components" | jq -r '.host_components[].HostRoles.host_name')
for host in $region_hosts; do
    curl -u $user:$password -H "X-Requested-By:ambari" -X POST "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$host/host_components/OPENTSDB_TSD"
done

# install now & wait for the installation to complete
install_id=$(curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"RequestInfo": {"context":"Install OPENTSDB daemon services"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' "http://headnodehost:8080/api/v1/clusters/$cluster/services/OPENTSDB" | jq -r '.Requests.id')
echo "Install request id is: $install_id"
percent_complete=0
while [ $percent_complete -lt 100 ]; do
    percent_complete=$(curl -u $user:$password -H "X-Requested-By:ambari" "http://headnodehost:8080/api/v1/clusters/$cluster/requests/$install_id" | jq -r '.Requests.progress_percent')
    echo $percent_complete
    sleep 3s
done

# finally, start the service
curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"RequestInfo": {"context":"Start OPENTSDB services"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' "http://headnodehost:8080/api/v1/clusters/$cluster/services/OPENTSDB"
