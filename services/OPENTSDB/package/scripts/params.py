#!/usr/bin/env python
from resource_management import *

# server configurations
config = Script.get_config()

opentsdb_version = config['configurations']['opentsdb-config']['opentsdb.opentsdb_version']
create_schema = config['configurations']['opentsdb-config']['opentsdb.create_schema']
zk_quorum = config['configurations']['hbase-site']['hbase.zookeeper.quorum']
zk_basedir = config['configurations']['hbase-site']['zookeeper.znode.parent']
opentsdb_site = config['configurations']['opentsdb-site']
tsd_port = config['configurations']['opentsdb-site']['tsd.network.port']
tsd_hosts = config['clusterHostInfo']['opentsdb_tsd_hosts']

print tsd_hosts