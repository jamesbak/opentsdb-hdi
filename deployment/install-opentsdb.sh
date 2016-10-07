#!/bin/bash          

user=$1
password=$2

echo "$(date +%T) Starting custom action script for provisioning OpenTSDB as an Ambari service"
apt-get install jq
wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/bin/jq

cluster=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters | jq -r .items[0].Clusters.cluster_name)
stack_name=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters/$cluster/stack_versions | jq -r '.items[0].ClusterStackVersions.stack')
stack_version=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters/$cluster/stack_versions | jq -r '.items[0].ClusterStackVersions.version')
echo "$(date +%T) Cluster: $cluster, Stack: $stack_name-$stack_version" 

cd /var/lib/ambari-server/resources/stacks/$stack_name/$stack_version/services
wget "https://github.com/jamesbak/opentsdb-hdi/files/514799/OPENTSDB.tar.gz" -O /tmp/OPENTSDB.tar.gz
tar -xvf /tmp/OPENTSDB.tar.gz
chmod -R 644 OPENTSDB
sed -i "s/\(agent.auto.cache.update=\).*/\1true/" /etc/ambari-server/conf/ambari.properties
echo "$(date +%T) Refreshing and restarting Ambari server"
ambari-server refresh-stack-hash

# metrics - add our metrics to the whitelist & recycle the metrics collector
cat OPENTSDB/metrics.json | jq -r '.OPENTSDB_TSD.Component[0].metrics.default[].metric' >> /etc/ambari-metrics-collector/conf/whitelistedmetrics.txt
cat OPENTSDB/metrics.json | jq -r '.OPENTSDB_PROXY.Component[0].metrics.default[].metric' >> /etc/ambari-metrics-collector/conf/whitelistedmetrics.txt

# Only perform the remainder on the active head nodes (as defined by headnodehost)
head_ip=$(getent hosts headnodehost | awk '{ print $1; exit }')
is_active_headnode=$(expr "$(hostname -i)" == "$head_ip")
echo "$(date +%T) This node is active headnode: $is_active_headnode"

echo "$(date +%T) Processing service registration on active head node via background script"
wget "https://raw.githubusercontent.com/jamesbak/opentsdb-hdi/v0.3/deployment/create-ambari-services.sh" -O /tmp/create-opentsdb-ambari-services.sh
chmod 744 /tmp/create-opentsdb-ambari-services.sh
mkdir /var/log/opentsdb
echo "$(date +%T) Logging background activity to /var/log/opentsdb/create-ambari-services.out & /var/log/opentsdb/create-ambari-services.err"
nohup /tmp/create-opentsdb-ambari-services.sh $user $password $cluster $is_active_headnode >/var/log/opentsdb/create-ambari-services.out 2>/var/log/opentsdb/create-ambari-services.err &
echo "$(date +%T) OpenTSDB has been installed and TSD components have been deployed to all HBase region servers"



