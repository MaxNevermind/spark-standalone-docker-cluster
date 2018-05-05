## About the project
This project can be used for creating Spark standalone cluster on Docker. It includes a docker file for creating 
a Spark Docker container and a deployment script.
___

## Main components of a cluster & main resources related parameters
 - Spark application. User program built on Spark. Consists of a driver and executors on the cluster.
 - Spark Standalone Master. Spark Standalone master node process that manages application running on a cluster. It doesn't 
 require a lot of resources by itself. There is only one in a cluster.  
 - Spark Standalone Worker. Spark Standalone slave node process that manages allocation resource to applications on a 
  slave node where it is running. It doesn't require a lot of resources by itself. The amount of resources available for 
  allocation is set by `WORKER_MEMORY` & `WORKER_CORES`. 
 - Driver. The process of an application that creates the SparkContext. Ideally It doesn't require a lot of resources by itself. 
  There is only one in per each application.
 - Executor. The process running the main heavy lifting logic of the application. There are one per each worker for each application.
 
#### Spark cluster level resources related parameters 
 - `WORKER_MEMORY` Amount of memory available per each worker. 
 - `WORKER_CORES` Number of cores available per each worker.
 
#### Spark application level resources related parameters
 - `spark.cores.max` A number of cores in total for all workers to be taken by an application. Example of a value: `4`, 
 if not set then all available cores of the cluster. 
 - `spark.executor.memory` An amount of memory per each worker to be taken by an application. Example of a value: `2g`, 
 if not set then `1g` on each worker.
  
#### Example of resource allocation
You started a cluster, it has 4 salves(`SLAVE_IPS`) and you set `WORKER_CORES=4` & `WORKER_MEMORY=4g`. There is already 
a running application with settings such as: `spark.cores.max=4` & `spark.executor.memory=2g`. Then the amount of free 
resources is:
 - 12 cores for the entire cluster = 4 slaves with workers * 4 cores each - 4 cores taken by running application
 - 2Gb memory for each worker = 4 Gb memory per each worker - 2 Gb per each worker taken by running application
___



## Installation
- Set deployment config env variables. You can find an example of how to properly set them in a file(`deploy-config.sh`).
- Run a deployment script(`deploy.sh`) 
#### Prerequisites:
- Docker is has to be installed on cluster machines.
- You need password-less SSH login to each of the machines in a cluster from a deployment machine.
___


## Spark Standalone monitoring tool
To see worker's and applications's state and available\used resources you can use Spark standalone WEB UI, 
which is available under `http://MASTER_IP:MASTER_PORT`. To see Spark UI for finished application you can use a History 
server WEB UI, which is available under `http://MASTER_IP:HISTORY_SERVER_WEB_UI_PORT`. You can access Executor's logs in 
History server, for a driver logs you have to look into a mounted volume `/tmp/docker-mounts/${clusterPrefix}-driver-logs`
on a master machine.
___


## Running multiple applications at once on a Spark Standalone cluster.
Spark Standalone cluster can run multiple applications at once. The key parameterы you need to set for each application 
are  `spark.cores.max` and `spark.executor.memory`, note that setting `spark.executor.cores` and `spark.executor.instances` **will not work** on 
Standalone Spark cluster! If you set `spark.executor.cores` it limits application resources but other application are not
be able to start even if there are free resources, they get into `Waiting` status and they wait until previous running 
application is finished.
#### Resource sharing on on a Spark Standalone cluster.
You can implement you own resource sharing sub-system over the top of Spark Standalone capabilities. There is a rest API
available under `http://MASTER_IP:HISTORY_SERVER_WEB_UI_PORT/api/v1`. In particular that is a request which returns 
running applications `http://MASTER_IP:HISTORY_SERVER_WEB_UI_PORT/api/v1/applications?status=running`
 
![Running applications](doc/HistoryServerRest_RunningApplications.png?raw=true "Running applications")

and that is a request which returns environment settings for specified `APPLICATION_ID` `http://localhost:18080/api/v1/applications/APPLICATION_ID/environment`. 

![Application env settings](doc/HistoryServerRest_ApplicationEnvSettings.png?raw=true "Application env settings")

You can then look for settings responsible for resource allocation for an application: 
 - `spark.cores.max`  example of a value: "16", if not set then all available cores of the cluster and it won't be able 
to run with the other applications in parallel, look for the explanation above
 - `spark.executor.memory` example of a value: "2g", if not set then 1g

Aggregating those settings for all running applications gives you a total amount of used resources and if you know 
the total amount of resources available on the cluster you can subtract one from another and get the amount of current 
free resources.

___

## Useful paths inside containers
#### Master container
- `/usr/share/spark/logs/` Spark standalone Master logs
- `/usr/share/logs/spark_log.log` Spark application driver logs. All of them, if there were more than one app run on a 
cluster. Note that this log location is for our configuration of `log4j.properties` and when Spark application 
are submitted in client mode. If applications are submitted in cluster mode then Driver logs location might change. 
- `/tmp/spark-events/` It's Spark eventLog directory. It's used by Spark History server for reconstructing Spark UI after an app finishes. 
Note that if you start application from outside of cluster's Spark containers then spark-event directory is determined by that
Spark installation's config. In that case you have to set `spark.eventLog.enabled` to true and set `spark.eventLog.dir` 
to `/tmp/docker-mounts/${clusterPrefix}-spark-events` on the host machine, that directory is used by master docker container 
as a storage of spark-events, you can find how it's mounted for a master container in `deploy.sh`.
#### Worker container
- `/usr/share/spark/logs/` Spark standalone Worker logs
- `/usr/share/logs/spark_log.log` Spark application executors logs. All of them, if there were more than one app run on a 
cluster. Configured in `log4j.properties`.
- `/usr/share/spark/work/app_id/executor_id/` App working directory including stderr & stdout & app jar
___



## Miscellaneous
#### Multiple clusters on the same cluster
To run multiple clusters on the same machines you have to change config env variables : `CLUSTER_PREFIX`, `MASTER_PORT`, 
`MASTER_WEB_UI_PORT`, `HISTORY_SERVER_WEB_UI_PORT` for each new cluster.
Also if you want to run multiple Workers on the same node then you might benefit from using Dockers's `--cpuset-cpus`
parameter. It splits CPUs between Docker processes. An example of setting 4-7 CPUs of a machine for Docker process: 
`docker run --cpuset-cpus="4-7" ...` 
 
 
## Endpoints
#### Master
- Spark Standalone server UI `http://MASTER_IP:MASTER_WEB_UI_PORT/`
- Spark History Server UI `http://MASTER_IP:HISTORY_SERVER_WEB_UI_PORT/`
- Spark Application UI `http://MASTER_IP:404x/` It takes first free port 4040, 4041 etc.

#### Slaves
- Spark Worker UI `http://SLAVE_IP:808x/` It takes first free port 8081, 8082 etc.

## OracleJDK
If you want to use OracleJDK there is Dockerfile-OracleJDK file which you can use. I didn't want to use it because, as I understand, the current license of OracleJDK doesn't allow to distribute it inside a docker container build on Linux.
