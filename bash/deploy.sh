#!/usr/bin/env bash

# This is a deployment script for Docker spark cluster, see README.md for more details.

set -e

USAGE="    Usage: deploy.sh (start|stop|restart)

    Description:
    This script is purposed for deploying a Spark docker cluster.

    Prerequisites:
    -Docker is has to be installed on cluster machines.
    -You need password-less SSH login to each of the machines in a cluster from a deployment machine.
    -You have to set config environment variables before running this script."

if (( $# < 1 )); then
    echo "$USAGE"
    exit 1
fi

echo "Checking existence of all needed configuration environment variables"
: ${SSH_KEY_PATH?"Need to set SSH_KEY_PATH"}
: ${CLUSTER_USER?"Need to set CLUSTER_USER"}
: ${MASTER_IP?"Need to set MASTER_IP"}
: ${SLAVE_IPS?"Need to set SLAVE_IPS"}
: ${CLUSTER_PREFIX?"Need to set CLUSTER_PREFIX"}
: ${WORKER_NUMBER_PER_SLAVE?"Need to set WORKER_NUMBER_PER_SLAVE"}
: ${WORKER_MEMORY?"Need to set WORKER_MEMORY"}
: ${WORKER_CORES?"Need to set WORKER_CORES"}
: ${SPARK_IMAGE?"Need to set SPARK_IMAGE"}
: ${MASTER_PORT?"Need to set MASTER_PORT"}
: ${MASTER_WEB_UI_PORT?"Need to set MASTER_WEB_UI_PORT"}

# SSH params
sshKeyPath=$SSH_KEY_PATH
clusterUser=$CLUSTER_USER

# IPs
masterIp=$MASTER_IP
slaveIps=(${SLAVE_IPS//;/ })

# Cluster params
clusterPrefix=$CLUSTER_PREFIX
workerNumberPerSlave=$WORKER_NUMBER_PER_SLAVE
workerMemory=$WORKER_MEMORY
workerCores=$WORKER_CORES
sparkImage=$SPARK_IMAGE

# Ports
masterPort=$MASTER_PORT
masterWebUIPort=$MASTER_WEB_UI_PORT

function startMaster {
    echo "Starting master"
    hostIp=$1
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$masterIp \
        "sudo docker run -id \
            --restart unless-stopped \
            --log-opt max-size=200m \
            --net=host \
            --name='${clusterPrefix}_spark_master' \
            $sparkImage \
            /bin/bash -c \
            '/usr/share/spark/sbin/start-master.sh --port $masterPort --webui-port $masterWebUIPort;
            /bin/bash'"
}

function startSlave {
    hostIp=$1
    workerIdx=$2
    echo "Starting worker #$workerIdx on $hostIp"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$hostIp \
        "sudo docker run -id \
            --restart unless-stopped \
            --log-opt max-size=200m \
            --net=host \
            --name='${clusterPrefix}_spark_worker_${workerIdx}' \
            $sparkImage \
            /bin/bash -c \
            '/usr/share/spark/sbin/start-slave.sh spark://$masterIp:$masterPort --cores $workerCores --memory $workerMemory;
            /bin/bash'"
}


function stopMaster {
    echo "Stopping master"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$masterIp \
        "sudo docker exec '${clusterPrefix}_spark_master' /usr/share/spark/sbin/stop-master.sh"
    echo "Stopping master docker containers"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$masterIp \
        "sudo docker ps -a --format '{{.Names}}' --filter 'name=${clusterPrefix}_spark_master' | sudo xargs sudo docker stop"
    echo "Removing master docker containers"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$masterIp \
        "sudo docker ps -a --format '{{.Names}}' --filter 'name=${clusterPrefix}_spark_master' | sudo xargs sudo docker rm -fv"
}

function stopSlave {
    hostIp=$1
    echo "Stopping workers"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$hostIp \
        "sudo docker ps -a --format '{{.Names}}' --filter 'name=${clusterPrefix}_spark_worker' | sudo xargs -I NAME docker exec NAME /usr/share/spark/sbin/stop-slave.sh"
    echo "Stopping worker docker containers"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$hostIp \
        "sudo docker ps -a --format '{{.Names}}' --filter 'name=${clusterPrefix}_spark_worker' | sudo xargs docker stop"
    echo "Removing worker docker containers"
    ssh -o "StrictHostKeyChecking no" -i $sshKeyPath $clusterUser@$hostIp \
        "sudo docker ps -a --format '{{.Names}}' --filter 'name=${clusterPrefix}_spark_worker' | sudo xargs docker rm -fv"
}

function startCluster {
    echo "Starting cluster $clusterPrefix"

    startMaster
    workerIdx=0
    for slaveIp in ${slaveIps[@]}
    do
        for ((workerIdx = 1 ; workerIdx <= $workerNumberPerSlave ; workerIdx++ ))
        do
            startSlave $slaveIp $workerIdx
        done
    done

    echo "Cluster is started"
}

function stopCluster {
    echo "Stopping cluster $clusterPrefix"

    stopMaster
    for slaveIp in ${slaveIps[@]}
    do
        stopSlave $slaveIp
    done

    echo "Cluster is stopped"
}

case "$1" in
"start")
    startCluster
    ;;
"stop")
    stopCluster
    ;;
"restart")
    stopCluster
    startCluster
    ;;
*)
    echo "$USAGE"
    exit 1
    ;;
esac