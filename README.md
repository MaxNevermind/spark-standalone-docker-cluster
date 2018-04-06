
# Description:

This project can be used for creating Spark standalone cluster on Docker. It includes a docker file for creating 
a Spark Docker container and a deployment script.

# Deployment on a cloud
- Set deployment config env variables. You can find an example of how to properly set them in a file(`deploy-config.sh`).
- Run a deployment script(`deploy.sh`) 

## Prerequisites:
- Docker is has to be installed on cluster machines.
- You need password-less SSH login to each of the machines in a cluster from a deployment machine.

# Logs location
You can find most of available logs in Spark UI http://MASTER_IP:MASTER_PORT. Below there are log locations inside 
Docker containers, those are for our configuration of `log4j.properties`, when Spark application are submitted 
in client mode. If applications are submitted in cluster mode then Driver logs location might change. 

## Master container
- /usr/share/spark/logs/ Spark standalone Master logs
- /usr/share/logs/spark_log.log Spark application driver logs. All of them, if there were more than one app run on a 
cluster. Configured in `log4j.properties`.
- /tmp/spark-events/ It's Spark eventLog directory. it's needed for reconstructing Spark UI after an app finishes.

## Worker container
- /usr/share/spark/logs/ Spark standalone Worker logs
- /usr/share/logs/spark_log.log Spark application executors logs. All of them, if there were more than one app run on a 
cluster. Configured in `log4j.properties`.
- /usr/share/spark/work/app_id/executor_id/ stderr & stdout & app jar

# Miscellaneous
If you want to run multiple Workers on the same node then you might benefit from using Dockers's `--cpuset-cpus`
parameter. It splits CPUs between Docker processes. An example of setting 4-7 CPUs of a machine for Docker process: 
`docker run --cpuset-cpus="4-7" ...`