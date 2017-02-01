#!/bin/bash
# (c) Copyright IBM Corp. 2017.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# handle config files
if [ ! -z "$1" ]; then
  if [ ! -f $1 ]; then
        echo "File not found!"
        exit 1
  else 
    source $1
  fi
else 
  source $DIR/config
fi

SPARK_CONF=${SPARK_CONF} \
  SPARK_USER=${SPARK_USER} \
  WORKBOOK_NAME=${WORKBOOK_NAME} \
  WORKBOOK_IP=${WORKBOOK_IP} \
  WORKBOOK_UI_PORT=${WORKBOOK_PORT} \
  WORKBOOK_VOLUME=${WORKBOOK_VOLUME} \
  WORKBOOK_DEBUG=${WORKBOOK_DEBUG} \
  SPARK_SECURITY_CONF=${SPARK_SECURITY_CONF} \
  WBSPARK_CONF=${WBSPARK_CONF} \
  docker-compose -f $DIR/docker-compose.yml -p $WORKBOOK_NAME down
