#!/bin/bash
# (c) Copyright IBM Corp. 2016.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# the variables in this file are only used to silence the warnings at build time
WORKBOOK_PORT=$WORKBOOK_PORT WORKBOOK_NAME=$WORKBOOK_NAME WORKBOOK_VOLUME=$WORKBOOK_VOLUME WORKBOOK_DEBUG=$WORKBOOK_DEBUG WORKBOOK_IP=$WORKBOOK_IP \
 SPARK_PORT=$SPARK_PORT SPARK_HOST=$SPARK_HOST SPARK_CPUS=$SPARK_CPUS SPARK_MEM=$SPARK_MEM SPARK_USER=$SPARK_USER \
 docker-compose -f $DIR/docker-compose.yml build $1
