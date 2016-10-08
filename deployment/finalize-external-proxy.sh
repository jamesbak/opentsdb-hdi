#!/bin/bash          
# Background script to complete installation of OpenTSDB external proxy service on edge node.
# The reason why we need to split this out is that the custom action script is being run by Ambari. When we kick off a request to install
# the proxy components on this server & wait, the task is being blocked by the custom action script, thus deadlock. 
# By running this script detached, one script doesn't block the other

user=$1
password=$2
cluster=$3
edge_hostname=$4

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
