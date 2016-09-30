#!/bin/bash          

opentsdb_ver=2.2.0
user=admin
password=P0rsche911!

wget https://raw.githubusercontent.com/OpenTSDB/opentsdb/v${opentsdb_ver}/src/create_table.sh
chmod +x create_table.sh
HBASE_HOME=/usr COMPRESSION=SNAPPY ./create_table.sh

wget https://github.com/OpenTSDB/opentsdb/releases/download/v${opentsdb_ver}/opentsdb-${opentsdb_ver}_all.deb
sudo dpkg -i opentsdb-${opentsdb_ver}_all.deb

#sudo apt-get install jq
wget http://stedolan.github.io/jq/download/linux64/jq 
chmod +x ./jq

cluster=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters | ./jq -r .items[0].Clusters.cluster_name)
latest_tag=$(curl -u $user:$password -k "http://headnodehost:8080/api/v1/clusters/$cluster/configurations?type=hbase-site" | ./jq -r '.items | sort_by(.version) | reverse | .[0].tag')
zk_quorum=$(curl -u $user:$password -k "http://headnodehost:8080/api/v1/clusters/$cluster/configurations?type=hbase-site&tag=$latest_tag" | ./jq -r '.items[0].properties."hbase.zookeeper.quorum"')
stack_name=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters/$cluster/stack_versions | jq -r '.items[0].ClusterStackVersions.stack')
stack_version=$(curl -u $user:$password http://headnodehost:8080/api/v1/clusters/$cluster/stack_versions | jq -r '.items[0].ClusterStackVersions.version')

config=/etc/opentsdb/opentsdb.conf
sudo sed -i '/^#tsd.storage.hbase.zk_quorum* /s/^#//' $config
sudo sed -i "s/\(tsd.storage.hbase.zk_quorum *= *\).*/\1$zk_quorum/" $config
sudo sed -i '/^#tsd.storage.hbase.zk_basedir* /s/^#//' $config
sudo sed -i "s/\(tsd.storage.hbase.zk_basedir *= *\).*/\1\/hbase-unsecure/" $config

