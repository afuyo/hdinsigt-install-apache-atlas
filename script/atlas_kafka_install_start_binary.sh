#!/bin/bash

#install atlas
sudo apt-cache search atlas-metadata*
sudo apt-get -y --allow-unauthenticated install atlas-metadata-2-6-1-10-4
# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

# Download binaries
download_file http://archive.apache.org/dist/lucene/solr/5.2.1/solr-5.2.1.tgz /tmp/solr-5.2.1.tgz

# Use this to set the new config value, needs 2 parameters. 
# You could check that $1 and $1 is set, but I am lazy
function set_config(){
    sudo sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $CONFIG
}

cd /usr/hdp/current

sudo mv /tmp/solr-5.2.1.tgz .


sudo tar -zxvf solr-5.2.1.tgz 


#Let's get zkhosts

ZKHOSTS=`grep -R zookeeper /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
if [ -z "$ZKHOSTS" ]; then
    ZKHOSTS=`grep -R zk /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`  
	
fi
#Configure file directories

ATLAS_HOME=/usr/hdp/current/atlas-client
SOLR_HOME=/usr/hdp/current/solr-5.2.1
KAFKA_HOME=/usr/hdp/current/kafka-broker

#CONFIGURE LOCAL KAFKA 

cd $KAFKA_HOME
CONFIG=$KAFKA_HOME/config/server.properties
source $CONFIG

set_config zookeeper.connect $ZKHOSTS

#START KAFKA
#sudo ./bin/kafka-server-start.sh config/server.properties
sudo nohup /usr/hdp/current/kafka-broker/bin/kafka-server-start.sh -daemon config/server.properties

#start Solr and create indexes required by Apache Atlas
cd $SOLR_HOME
#with examples
#sudo ./bin/solr start -e cloud -z $ZKHOSTS -noprompt

#without examples
sudo ./bin/solr start -c -m 1g -z $ZKHOSTS -a "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=1044"

export SOLR_CONF=/usr/hdp/current/solr-5.2.1/server/solr/configsets/basic_configs/conf
export SOLR_BIN=/usr/hdp/current/solr-5.2.1/bin/

sleep 10s

sudo ./bin/solr create -c vertex_index -d $SOLR_CONF -shards 1 -replicationFactor 1
sudo ./bin/solr create -c edge_index -d $SOLR_CONF -shards 1 -replicationFactor 1
sudo ./bin/solr create -c fulltext_index -d $SOLR_CONF -shards 1 -replicationFactor 1

#EDIT atlas-application.properties

CONFIG="$ATLAS_HOME/conf/atlas-application.properties"




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

cd $ATLAS_HOME/conf
# append values to atlas-application.properties necessary for hive-hook

echo "export atlas.hook.hive.keepAliveTime=10" | sudo tee -a atlas-application.properties 
echo "atlas.hook.hive.maxThreads=5"  | sudo tee -a atlas-application.properties 
echo "atlas.hook.hive.minThreads=5"  | sudo tee -a atlas-application.properties
echo "atlas.hook.hive.numRetries=3"  | sudo tee -a atlas-application.properties
echo "atlas.hook.hive.queueSize=1000"  | sudo tee -a atlas-application.properties
echo "atlas.hook.hive.synchronous=false"  | sudo tee -a atlas-application.properties

#edit atlas_env.sh add


echo "export HBASE_CONF_DIR=/usr/hdp/current/hbase-client/conf" | sudo tee -a atlas-env.sh
echo "export SOLR_CONF=/usr/hdp/current/solr-5.2.1/server/solr/configsets/basic_configs/conf" | sudo tee -a atlas-env.sh
echo "export SOLR_BIN=/usr/hdp/current/solr-5.2.1/bin/" | sudo tee -a atlas-env.sh




#setup kafka topics
cd $ATLAS_HOME/bin
#sudo ./atlas_kafka_setup.py

#HIVE
export HIVE_CONF_DIR=/usr/hdp/current/hive-client/conf
export HADOOP_HOME=/usr/hdp/current/hadoop-client

#copy atlas-application.properties to hive conf directory

sudo cp $ATLAS_HOME/conf/atlas-application.properties $HIVE_CONF_DIR 

#test if topics has been setup
cd $KAFKA_HOME
#sudo ./bin/kafka-topics.sh --list --zookeeper $ZKHOSTS



#start atlas
cd $ATLAS_HOME
sudo ./bin/atlas_start.py
#sudo ./bin/quick_start.py 
