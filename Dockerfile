# (c) Copyright IBM Corp. 2017.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.
# A base Ubuntu 16.04 build that runs on z #
FROM s390x/ubuntu
USER root

# Build Minimal Notebook #
## Install Dependencies ##
RUN apt update
RUN apt install -y python3-pip python3-dev pax
RUN apt clean
RUN rm -rf /var/lib/apt/lists/*

## Set Environment Variables ##
RUN locale-gen en_US.UTF-8
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
ENV SHELL=/bin/bash
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV PATH=$PATH:/home/$NB_USER/.local/bin
ENV APACHE_SPARK_VERSION=2.0.2
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.3-src.zip
ENV JAVA_HOME=/opt/ibm/java

## Create User $NB_USER with UID=1000 ##
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER
RUN mkdir -p /opt/conda
RUN chown $NB_USER /opt/conda
RUN chown $NB_USER -R /usr/

USER $NB_USER
RUN mkdir /home/$NB_USER/work
RUN mkdir /home/$NB_USER/.jupyter
RUN mkdir /home/$NB_USER/.local

USER root
RUN cd /tmp
RUN pip3 install --upgrade pip
RUN pip install 'notebook==4.2'

COPY /files/start.sh /usr/local/bin/
COPY /files/start-notebook.sh /usr/local/bin/
COPY /files/start-singleuser.sh /usr/local/bin/
COPY /files/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

# Scala-Workbench Steps #
## Setup Java ##
RUN mkdir -p /opt/ibm/java
COPY files/ibm-java-s390x-sdk-8.0-3.12.bin /opt/ibm/java/ibm-java-s390x-sdk-8.0-3.12.bin
COPY files/installer.properties.java /opt/ibm/java/installer.properties
RUN chmod -R 755 /opt/ibm/java
WORKDIR /opt/ibm/java
RUN ./ibm-java-s390x-sdk-8.0-3.12.bin -f installer.properties
RUN rm -Rf /usr/lib/jvm/default-java
RUN mkdir -p /usr/lib/jvm/default-java
RUN ln -s /opt/ibm/java/* /usr/lib/jvm/default-java
RUN update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/default-java/bin/javac" 9999
RUN update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/default-java/bin/java" 9999
RUN update-alternatives --set java /usr/lib/jvm/default-java/bin/java

## Get Apache Spark Hadoop tar and extract it ##
WORKDIR /usr/local
COPY files/IBM_Spark_DK_2.0.2.0_Linux_s390x.bin /usr/local/IBM_Spark_DK_2.0.2.0_Linux_s390x.bin
COPY files/installer.properties.spark /usr/local/installer.properties
RUN chmod 755 /usr/local/IBM_Spark_DK_2.0.2.0_Linux_s390x.bin
RUN ./IBM_Spark_DK_2.0.2.0_Linux_s390x.bin -f installer.properties
ENV SPARK_HOME=/usr/local/spark

## Set some permissions for user joyvyan ##
RUN chown -R $NB_USER $SPARK_HOME
RUN chown -R $NB_USER /usr/local/lib/python3.5/
RUN chmod +x /usr/local/lib/python3.5/

WORKDIR /home/$NB_USER/work
USER $NB_USER
RUN pip install -i https://pypi.anaconda.org/hyoon/simple toree
RUN jupyter toree install --user
