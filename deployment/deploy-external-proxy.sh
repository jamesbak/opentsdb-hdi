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
sleep 30s
# install now & wait for the installation to complete
install_id=$(curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"HostRoles": {"state": "INSTALLED"}}' "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$edge_hostname/host_components/OPENTSDB_PROXY" | jq -r '.Requests.id')
echo "$(date +%T) Install request id is: $install_id"
percent_complete=0
while [ $percent_complete -lt 100 ]; do
    complete=$(curl -u $user:$password -H "X-Requested-By:ambari" "http://headnodehost:8080/api/v1/clusters/$cluster/requests/$install_id" | jq -r '.Requests.progress_percent')
    percent_complete=$(printf "%.0f" $complete)
    echo "$(date +%T) Install completion percentage: $percent_complete"
    sleep 3s
done
# Start the service component
echo "$(date +%T) Starting the OpenTSDB proxy service"
curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"HostRoles": {"state": "STARTED"}}' "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$edge_hostname/host_components/OPENTSDB_PROXY"
echo "$(date +%T) Completed installation of OpenTSDB proxy service"
