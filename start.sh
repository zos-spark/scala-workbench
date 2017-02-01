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

if [ -z "${WORKBOOK_IP:+x}" ]; then
  echo "Error:WORKBOOK_IP is not set"
  exit 1
fi

if [ -z "${WORKBOOK_UI_PORT:+x}" ]; then
  echo "Error: WORKBOOK_UI_PORT is not set"
  exit 1
fi

SPARK_CONF=""
if [ ! -z "${SPARK_HOST:+x}" ]; then
  if [ -z "${SPARK_PORT:+x}" ]; then
    echo "Error: SPARK_HOST is set, but no SPARK_PORT is set"
    exit 1
  fi
  SPARK_CONF="--master=spark://${SPARK_HOST}:${SPARK_PORT}"
fi

if [ ! -z "${SPARK_CPUS:+x}" ]; then
  SPARK_CONF="${SPARK_CONF} --conf spark.cores.max=${SPARK_CPUS}"
fi

if [ ! -z "${SPARK_MEM:+x}" ]; then
  SPARK_CONF="${SPARK_CONF} --conf spark.executor.memory=${SPARK_MEM}"
fi

if [ ! -z "${SPARK_ADDITIONALCONF:+x}" ]; then
  SPARK_CONF="${SPARK_CONF} ${SPARK_ADDITIONALCONF}"
fi

WBSPARK_CONF=""
if [ ! -z "${WBSPARK_DRIVER_PORT:+x}" ]; then
  WBSPARK_CONF="${WBSPARK_CONF} --conf spark.driver.port=${WBSPARK_DRIVER_PORT}"
fi

if [ ! -z "${WBSPARK_FILESERVER_PORT:+x}" ]; then
  WBSPARK_CONF="${WBSPARK_CONF} --conf spark.fileserver.port=${WBSPARK_FILESERVER_PORT}"
fi

if [ ! -z "${WBSPARK_BLOCKMANAGER_PORT:+x}" ]; then
  WBSPARK_CONF="${WBSPARK_CONF} --conf spark.blockmanager.port=${WBSPARK_BLOCKMANAGER_PORT}"
fi

if [ ! -z "${WBSPARK_REPLCLASSSERVER_PORT:+x}" ]; then
  WBSPARK_CONF="${WBSPARK_CONF} --conf spark.replclassserver.port=${WBSPARK_REPLCLASSSERVER_PORT}"
fi

if [ ! -z "${WBSPARK_BROADCAST_PORT:+x}" ]; then
  WBSPARK_CONF="${WBSPARK_CONF} --conf spark.broadcast.port=${WBSPARK_BROADCAST_PORT}"
fi

if [ ! -z "${WBSPARK_EXECUTOR_PORT:+x}" ]; then
  WBSPARK_CONF="${WBSPARK_CONF} --conf spark.executor.port=${WBSPARK_EXECUTOR_PORT}"
fi

if [ ! -z "${SPARK_SECURITY:+x}" ]; then
  SPARK_SECURITY_GENERIC="--conf spark.network.sasl.serverAlwaysEncrypt=true --conf spark.ssl.enabled=true --conf spark.ssl.protocol=TLSv1.2 --conf spark.ssl.fs.enabled=true"
  SPARK_SECURITY_SECRET="--conf spark.authenticate.enableSaslEncryption=true --conf spark.authenticate=true --conf spark.authenticate.secret=${SPARK_SECRET}"

  SPARK_SECURITY_KEYSTORE="--conf spark.ssl.keyStore=${SPARK_KEYSTORE_PATH}/${SPARK_KEYSTORE} --conf spark.ssl.keyStorePassword=${SPARK_KEYSTORE_PASS}"
  SPARK_SECURITY_TRUSTSTORE="--conf spark.ssl.trustStore=${SPARK_TRUSTSTORE_PATH}/${SPARK_TRUSTSTORE} --conf spark.ssl.trustStorePassword=${SPARK_TRUSTSTORE_PASS}"
  SPARK_SECURITY_SSL_KEY="--conf spark.ssl.keyPassword=${SPARK_SSL_PASS}"

  SPARK_SECURITY_CONF="${SPARK_SECURITY_GENERIC} ${SPARK_SECURITY_SECRET} ${SPARK_SECURITY_KEYSTORE} ${SPARK_SECURITY_TRUSTSTORE} ${SPARK_SECURITY_SSL_KEY}"
fi

docker volume create --name $WORKBOOK_VOLUME

SPARK_CONF=${SPARK_CONF} \
  SPARK_USER=${SPARK_USER} \
  WORKBOOK_NAME=${WORKBOOK_NAME} \
  WORKBOOK_IP=${WORKBOOK_IP} \
  WORKBOOK_UI_PORT=${WORKBOOK_PORT} \
  WORKBOOK_VOLUME=${WORKBOOK_VOLUME} \
  WORKBOOK_DEBUG=${WORKBOOK_DEBUG} \
  SPARK_SECURITY_CONF=${SPARK_SECURITY_CONF} \
  WBSPARK_CONF=${WBSPARK_CONF} \
  docker-compose -f $DIR/docker-compose.yml -p $WORKBOOK_NAME up -d

if [ ! -z "${SPARK_SECURITY:+x}" ]; then
  docker exec -u root ${WORKBOOK_NAME} mkdir -p ${SPARK_TRUSTSTORE_PATH}
  docker cp ${SPARK_TRUSTSTORE_LOCAL} ${WORKBOOK_NAME}:${SPARK_TRUSTSTORE_PATH}/${SPARK_TRUSTSTORE}
  docker exec -u root ${WORKBOOK_NAME} mkdir -p ${SPARK_KEYSTORE_PATH}
  docker cp ${SPARK_KEYSTORE_LOCAL} ${WORKBOOK_NAME}:${SPARK_KEYSTORE_PATH}/${SPARK_KEYSTORE}
fi
