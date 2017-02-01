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

# Build the Spark configuration, based on the configuration settings.
# Settings for the Spark cluster on z/OS
CONFIG=""

if [ ! -z "${SPARK_HOST:+x}" ]; then
  if [  ! -z "${SPARK_PORT:+x}" ]; then
    CONFIG="$CONFIG --master=spark://${SPARK_HOST}:${SPARK_PORT}"
  else
    echo "Error: SPARK_PORT is not set"
    exit 1
  fi
else
  echo "Error: SPARK_HOST is not set"
  exit 1
fi

if [ ! -z "${SPARK_CPUS:+x}" ]; then
  SPARK_CONF="${SPARK_CONF} --conf spark.cores.max=${SPARK_CPUS}"
fi

if [ ! -z "${SPARK_MEM:+x}" ]; then
  SPARK_CONF="${SPARK_CONF} --conf spark.executor.memory=${SPARK_MEM}"
fi

CONFIG="$CONFIG SPARK_USER=${SPARK_USER} ${SPARK_ADDITIONAL_CONF}"

# Settings for the local workbook
if [ ! -z "${WORKBOOK_IP:+x}" ]; then
   CONFIG="$CONFIG WORKBOOK_IP=${WORKBOOK_IP}"
else
  echo "Error: WORKBOOK_IP is not set"
  exit 1
fi

if [ ! -z "${WORKBOOK_PORT:+x}" ]; then
   CONFIG="$CONFIG WORKBOOK_PORT=${WORKBOOK_PORT}"
else
  echo "Error: WORKBOOK_PORT is not set"
  exit 1
fi

CONFIG="$CONFIG WORKBOOK_NAME=${WORKBOOK_NAME} WORKBOOK_VOLUME=${WORKBOOK_VOLUME} WORKBOOK_DEBUG=${WORKBOOK_DEBUG}"

# Settings to allow the workbook and the spark cluster to communicate
if [ ! -z "${WBSPARK_DRIVER_PORT:+x}" ]; then
  CONFIG="$CONFIG --conf spark.driver.port=${WBSPARK_DRIVER_PORT}"
fi

if [ ! -z "${WBSPARK_FILESERVER_PORT:+x}" ]; then
  CONFIG="$CONFIG --conf spark.fileserver.port=${WBSPARK_FILESERVER_PORT}"
fi

if [ ! -z "${WBSPARK_BLOCKMANAGER_PORT:+x}" ]; then
  CONFIG="$CONFIG --conf spark.blockmanager.port=${WBSPARK_BLOCKMANAGER_PORT}"
fi

if [ ! -z "${WBSPARK_REPLCLASSSERVER_PORT:+x}" ]; then
  CONFIG="$CONFIG --conf spark.replclassserver.port=${WBSPARK_REPLCLASSSERVER_PORT}"
fi

if [ ! -z "${WBSPARK_EXECUTOR_PORT:+x}" ]; then
  CONFIG="$CONFIG --conf spark.executor.port=${WBSPARK_EXECUTOR_PORT}"
fi

docker volume create --name $WORKBOOK_VOLUME

SPARK_CONF=${CONFIG} \
  SPARK_HOST=${SPARK_HOST} \
  SPARK_PORT=${SPARK_PORT} \
  SPARK_CPUS=${SPARK_CPUS} \
  SPARK_MEM=${SPARK_MEM} \
  SPARK_USER=${SPARK_USER} \
  WORKBOOK_IP=${WORKBOOK_IP} \
  WORKBOOK_PORT=${WORKBOOK_PORT} \
  WORKBOOK_NAME=${WORKBOOK_NAME} \
  WORKBOOK_VOLUME=${WORKBOOK_VOLUME} \
  WORKBOOK_DEBUG=${WORKBOOK_DEBUG} \
  docker-compose -f $DIR/docker-compose.yml -p $WORKBOOK_NAME up -d

#docker exec -u root $WORKBOOK_NAME jupyter toree install --spark_opts="--master=spark://${SPARK_HOST}:${SPARK_PORT} --conf spark.cores.max=$SPARK_CPUS --conf spark.executor.memory=$SPARK_MEM"
#docker exec -u root $WORKBOOK_NAME jupyter toree install --spark_opts="--master=spark://${SPARK_HOST}:${SPARK_PORT} --conf spark.cores.max=$SPARK_CPUS --conf spark.executor.memory=$SPARK_MEM --jars /home/jovyan/work/dv-jdbc-3.1.jar,/home/jovyan/work/log4j-api-2.6.2.jar,/home/jovyan/work/log4j-core-2.6.2.jar"
