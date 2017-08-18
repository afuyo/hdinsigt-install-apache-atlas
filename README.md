# Install Apache Atlas on HDInsight
Scripts provided install Apache Atlas and some of the components required by Atlas, on HDInsigt platform 3.5. As for now it is mainly for testing purposes.

## What is Apache Atlas?
Apache Atlas provides scalable governance for Enterprise Hadoop that is driven by metadata. Atlas, at its core, is designed to easily model new business processes and data assets with agility. This flexible type system allows exchange of metadata with other tools and processes within and outside of the Hadoop stack, thereby enabling platform-agnostic governance controls that effectively address compliance requirements

## Prerequisites

Apache Atlas requires following components:
* Ambari Infra (which includes an internal HDP Solr Cloud instance) or an externally managed Solr Cloud instance.
* HBase (used as the Atlas Metastore).
* Kafka (provides a durable messaging bus).

[NOTE] For testing purposes in order to keep it simple a local instance of Solr and Kafka will be installed on HBASE cluster.

## Installation steps

1. Download and build the latest release of Apache Atlas.(see build.sh)
2. Extract binary to /usr/hdp/current on the head node.
3. Run the installkafka.sh script if necessary.
4. Run installatlas.sh script. The script installs and starts Solr in cloud mode.
