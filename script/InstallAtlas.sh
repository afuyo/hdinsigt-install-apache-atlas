#!/bin/bash

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

# Download binaries
download_file http://apache.claz.org/kafka/0.11.0.0/kafka_2.11-0.11.0.0.tgz /tmp/kafka_2.11-0.11.0.0.tgz
download_file http://archive.apache.org/dist/lucene/solr/5.2.1/solr-5.2.1.tgz /tmp/solr-5.2.1.tgz
#scp apache-atlas-0.8-incubating-SNAPSHOT-bin.tar.gz sshuser@hbasesolr03-ssh.azurehdinsight.net:/tmp

cd /usr/hdp/current
sudo mv /tmp/kafka_2.11-0.11.0.0.tgz .
sudo mv /tmp/apache-atlas-0.8-incubating-SNAPSHOT-bin.tar.gz .
sudo mv /tmp/solr-5.2.1.tgz .

sudo tar -xzvf apache-atlas-0.8-incubating-SNAPSHOT-bin.tar.gz 
sudo tar -xzvf kafka_2.11-0.11.0.0.tgz
sudo tar -zxvf solr-5.2.1.tgz 

#Let's get zkhosts

#Let's get zkhosts

ZKHOSTS=`grep -R zookeeper /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
if [ -z "$ZKHOSTS" ]; then
    ZKHOSTS=`grep -R zk /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`  
	
fi

#remove temporary file download
sudo rm -f /tmp/kafka_2.11-0.11.0.0.tgz 
sudo rm -f /tmp/apache-atlas-0.8-incubating-SNAPSHOT-bin.tar.gz 
sudo rm -f /tmp/solr-5.2.1.tgz 

#start Solr and create indexes required by Apache Atlas
cd /usr/hdp/current/solr-5.2.1/
sudo ./bin/solr start -e cloud -z $ZKHOSTS -noprompt

export SOLR_CONF=/usr/hdp/current/solr-5.2.1/server/solr/configsets/basic_configs/conf
export SOLR_BIN=/usr/hdp/current/solr-5.2.1/bin/

sudo ./bin/solr create -c vertex_index -d $SOLR_CONF -shards 1 -replicationFactor 1
sudo ./bin/solr create -c edge_index -d $SOLR_CONF -shards 1 -replicationFactor 1
sudo ./bin/solr create -c fulltext_index -d $SOLR_CONF -shards 1 -replicationFactor 1

#EDIT atlas-application.properties

CONFIG="/usr/hdp/current/apache-atlas-0.8-incubating-SNAPSHOT/conf/atlas-application.properties"

# Use this to set the new config value, needs 2 parameters. 
# You could check that $1 and $1 is set, but I am lazy
function set_config(){
    sudo sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $CONFIG
}

#NEW CONFIGURATION VALUES

EMBEDDED="false"
BOOTSTRAP="localhost:9092"

# LOAD THE CONFIG FILE
source $CONFIG

# SET THE NEW VALUES
set_config atlas.graph.storage.hostname $ZKHOSTS 
set_config atlas.graph.index.search.solr.zookeeper-url $ZKHOSTS
set_config atlas.notification.embedded $EMBEDDED
set_config atlas.kafka.zookeeper.connect $ZKHOSTS
set_config atlas.kafka.bootstrap.servers $BOOTSTRAP
set_config atlas.audit.hbase.zookeeper.quorum $ZKHOSTS

#edit atlas_env.sh add
cd /usr/hdp/current/apache-atlas-0.8-incubating-SNAPSHOT/conf

echo "export HBASE_CONF_DIR=/usr/hdp/2.5.5.3-2/hbase/conf" | sudo tee -a atlas-env.sh
echo "export HBASE_CONF_DIR=/usr/hdp/2.5.5.3-2/hbase/conf" | sudo tee -a atlas-env.sh
echo "export SOLR_CONF=/usr/hdp/current/solr-5.2.1/server/solr/configsets/basic_configs/conf" | sudo tee -a atlas-env.sh
echo "export SOLR_BIN=/usr/hdp/current/solr-5.2.1/bin/" | sudo tee -a atlas-env.sh

#edit $KAFKA_HOME/server.properties 

cd /usr/hdp/current/kafka_2.11-0.11.0.0/
CONFIG=/usr/hdp/current/kafka_2.11-0.11.0.0/config/server.properties
set_config zookeeper.connect $ZKHOSTS

#start kafka server
sudo ./bin/kafka-server-start.sh config/server.properties

#setup kafka topics
cd /usr/hdp/current/apache-atlas-0.8-incubating-SNAPSHOT/bin
sudo ./atlas_kafka_setup.py

#test if topics has been setup
cd /usr/hdp/current/kafka_2.11-0.10.2.1/
sudo ./bin/kafka-topics.sh --list --zookeeper $ZKHOSTS

#start atlas
cd /usr/hdp/current/apache-atlas-0.8-incubating-SNAPSHOT/
sudo ./bin/atlas_start.py
sudo ./bin/quick_start.py 
