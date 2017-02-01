# Scala Workbench for IBM z/OS Platform for Apache Spark

<!-- (c) Copyright IBM Corp. 2017.  All Rights Reserved.
     Distributed under the terms of the Modified BSD License. -->

The Scala Workbench for IBM z/OS Platform for Apache Spark is based on [Project Jupyter](https://jupyter.org/).

This README demonstrates how to build the workbench as a Docker image, and how to run the workbench image as a Docker container on a Linux platform to drive work to an IBM z/OS Platform for Apache Spark cluster version 2.x.

>This approach is based on Java RMI and as such depends on a tight coupling between the client and server libraries.

## Prerequisites

As per the [Reference Architecture Diagram](https://ibm.box.com/shared/static/xm05xl372hkbmmj4eu9fhoq0kplytzp3.png), the following components of a deployment topology are required:

* IBM z/OS Platform for Apache Spark
  * [ShopZ - Product Ordering Details](https://www-304.ibm.com/software/shopzseries/ShopzSeries_public.wss)
  * [Installation Instructions](http://www-03.ibm.com/support/techdocs/atsmastr.nsf/WebIndex/WP102609) for details on how to setup your Spark environment.
* Docker Environment for Scala Workbench
  * As per the [Apache Spark component architecture requirements](https://spark.apache.org/docs/0.8.0/cluster-overview.html), a *driver program* should be run close to the worker nodes, preferably on the same local area network. The *driver program* must be network addressable to all nodes in the Spark cluster. **This implies that the target physical or virtual machine for the Scala Workbench must be located within the same network addressable environment as the hosted instance of IBM z/OS Platform for Apache Spark**.
  * See the [Docker installation instructions](https://docs.docker.com/engine/installation/) for your target docker environment. **Note: Testing has been done using Docker on Ubuntu (baremetal and VM)**.
    * [Docker Engine](https://docs.docker.com/engine/) 1.12.3+
    * [Docker Compose](https://docs.docker.com/compose/) 1.9.0+
* Python-pip - required during the build process
* Linux on z Systems for the build and runtime environments
  * A problem has been identified in Spark 2.x where data corruption occurs when a driver program and the Spark cluster run on platforms of different byte orders.  The details of the issue are described in [SPARK-12778](https://issues.apache.org/jira/browse/SPARK-12778).  Since z/OS is a big-endian platform, the Scala Workbench must run from Linux on z Systems.
  * This environment has been verified with Ubuntu and RHEL s390x platforms.


### Getting Started
The build process for the Scala Workbench requires access to multiple internet package sources.  In most enterprise environments that are isolated behind a firewall, such access is prohibited.  For this reason, it is often necessary to build the Docker image for the Scala Workbench on a system with access to the necessary resources, and then transfer that image to the runtime platform in the secure environment.

An ideal environment for this process is the [IBM LinuxONE Community Cloud](https://developer.ibm.com/linuxone/).  The build steps outlined here were performed on a LinuxONE Ubuntu VM, and tested by deploying the resulting Docker image on a LinuxONE RHEL VM

### Download Dependency files
* Clone the Scala Workbench from https://github.com/zos-spark/scala-workbench (or download the zip file) and locate it on a build system.
* **IBM Java 8+ 64-bit SDK for Linux on Z**: download the InstallAnywhere as root version from  https://developer.ibm.com/javasdk/downloads
  * You should have **ibm-java-sdk-8.0.3.22-390x-archive.bin** when the download completes.  Put this file in the scala-workbench/files directory that you have cloned.
* **Linux on z Systems 64-bit package for Apache Spark**: download from
http://www.ibm.com/developerworks/java/jdk/spark/index.html .
  * You should have **IBM_Spark_DK_2.0.2.0_linux_s390x.bin** when the download completes.
  * Put this file in the scala-workbench/files directory as well.

### Configure the Build Platform
* Install Docker engine
```
      sudo apt install docker.io
```
* Install the pip python installer
```
      sudo apt install -y python-pip
      pip install --upgrade pip
      sudo -H pip install backports.ssl_match_hostname --upgrade
```
* Use pip to install docker-compose
```
      sudo pip install docker-compose==1.9.0
```
* Add the admin user to the docker group
```
      sudo usermod -a -G docker [userid]
```

### Build the Workbench
* cd to the scala-wb directory
* Run the build tool.  This will create a Docker image containing a Jupyter server and the Toree kernel
```
      ./build.sh 2>&1 | tee build.log
```

### Move the Workbench Image to the Runtime Platform
Now that the Docker image for the workbench is built, it's time to take the image behind the firewall and onto the platform where it will run.
* Determine the image-id of zspark202/loz-scala-wb (note [image-id])
```
      docker images
```
* Save the image to an archive file.  You can give the tar file any name that makes sense.
```
      docker save -o [loz-scala-wb.tar] [image-id]
```
* Transfer the tar file for the image to the machine that will run the workbook.
* Load the image into Docker
```
      docker load -i [loz-scala-wb.tar]
```
* Tag the image to give it the necessary repository name.  This name is what docker-compose will use to start and stop containers from this image.
```
      docker tag [image-id] zspark202/loz-scala-wb
```

### Configure the Runtime Platform
The runtime environment requires the same Scala Workbench infrastructure (although not all of the same dependency files) as the build environment.  The difference on this platform is that we will use the start and stop tools instead of the build tool.  For this reason, you need to acquire the Scala Workbench package from https://github.com/zos-spark/scala-workbench, as on the build platform.

Since the runtime environment is behind a firewall, It's likely more convenient to download the zip file for the package, rather than cloning it.  Use the **Download ZIP** link from the **Clone or Download** button on the github site.
* Transfer the Scala Workbench zip file to the runtime platform
* Unzip the file in a well-known location
* cd to the scala-wb directory
* Edit the file named **config**.  This has all of the settings needed to configure the Scala Workbench to drive work to your target Spark cluster.  Set the values that correspond to your Spark environment.

### Start the Scala Workbench
This step  will create a Docker container from the Scala Workbench image and make an instance of the workbench active for use.
```
      ./start.sh
```

You can verify that the container is running using the docker ps command.  You should see something like this:
```
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS     
11a64db24526        zspark202/loz-scala-wb   "bash -c 'start-noteb"   19 hours ago        Up 19 hours
```
