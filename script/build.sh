#!/bin/bash

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

download_file https://github.com/apache/incubator-atlas/archive/release-0.8-rc1.tar.gz /tmp/release-0.8-rc1.tar.gz

sudo mv /tmp/release-0.8-rc1.tar.gz /usr/hdp/current/release-0.8-rc1.tar.gz
cd /usr/hdp/current

sudo tar -xzvf release-0.8-rc1.tar.gz

sudo apt-get install maven

export MAVEN_OPTS="-Xms2g -Xmx2g -XX:MaxPermSize=512M"
mvn clean package -DskipTests -Pdist,external-hbase-solr
