#!/bin/bash          

user=$1
password=$2

echo "$(date +%T) Starting custom action script for deploying edge node proxy for TSD servers"
apt-get install jq
wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/bin/jq

cluster=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters | jq -r .items[0].Clusters.cluster_name)
edge_hostname=$(hostname -f)
echo "$(date +%T) Cluster: $cluster, Host: $edge_hostname" 
curl -u $user:$password -H "X-Requested-By:ambari" -X POST "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$edge_hostname/host_components/OPENTSDB_PROXY"

wget "https://raw.githubusercontent.com/jamesbak/opentsdb-hdi/v0.3/deployment/finalize-external-proxy.sh" -O /tmp/finalize-external-proxy.sh
chmod 744 /tmp/finalize-external-proxy.sh
mkdir /var/log/opentsdb
echo "$(date +%T) Logging background activity to /var/log/opentsdb/finalize-external-proxy.out & /var/log/opentsdb/finalize-external-proxy.err"
nohup /tmp/finalize-external-proxy.sh $user $password $cluster $edge_hostname >/var/log/opentsdb/finalize-external-proxy.out 2>/var/log/opentsdb/finalize-external-proxy.err &
echo "$(date +%T) Completed installation of OpenTSDB proxy service"
