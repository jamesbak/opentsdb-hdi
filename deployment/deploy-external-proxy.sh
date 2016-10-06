#!/bin/bash          

user=$1
password=$2

apt-get install jq
wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/bin/jq

cluster=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters | jq -r .items[0].Clusters.cluster_name)
edge_hostname=$(hostname -f)
curl -u $user:$password -H "X-Requested-By:ambari" -X POST "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$edge_hostname/host_components/OPENTSDB_PROXY"
# install now & wait for the installation to complete
install_id=$(curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"HostRoles": {"state": "INSTALLED"}}' "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$edge_hostname/host_components/OPENTSDB_PROXY" | jq -r '.Requests.id')
echo "Install request id is: $install_id"
percent_complete=0
while [ $percent_complete -lt 100 ]; do
    percent_complete=$(curl -u $user:$password -H "X-Requested-By:ambari" "http://headnodehost:8080/api/v1/clusters/$cluster/requests/$install_id" | jq -r '.Requests.progress_percent')
    echo $percent_complete
    sleep 3s
done
# Start the service component
curl -u $user:$password -H "X-Requested-By:ambari" -X PUT -d '{"HostRoles": {"state": "STARTED"}}' "http://headnodehost:8080/api/v1/clusters/$cluster/hosts/$edge_hostname/host_components/OPENTSDB_PROXY"
