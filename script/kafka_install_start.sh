#!/bin/bash

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

# Download binaries
download_file http://apache.claz.org/kafka/0.11.0.0/kafka_2.11-0.11.0.0.tgz /tmp/kafka_2.11-0.11.0.0.tgz

cd /usr/hdp/current
sudo mv /tmp/kafka_2.11-0.11.0.0.tgz .

sudo tar -xzvf kafka_2.11-0.11.0.0.tgz

#Let's get zkhosts

ZKHOSTS=`grep -R zookeeper /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
if [ -z "$ZKHOSTS" ]; then
    ZKHOSTS=`grep -R zk /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`  
	
fi

# Use this to set the new config value, needs 2 parameters. 
# You could check that $1 and $1 is set, but I am lazy
function set_config(){
    sudo sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $CONFIG
}

#edit $KAFKA_HOME/server.properties 

cd /usr/hdp/current/kafka_2.11-0.11.0.0/
CONFIG=/usr/hdp/current/kafka_2.11-0.11.0.0/config/server.properties
source $CONFIG

set_config zookeeper.connect $ZKHOSTS

#start kafka server
sudo ./bin/kafka-server-start.sh config/server.properties
