#!/usr/bin/env bash

# This is a pattern of a config file for deployment script.

# IMPORTANT! Do not just run this file, use "Sourcing a File" and after that run a deployment script itself.
# Example
# Wrong: "./deploy-config.sh"
# Correct: ". ./deploy-config.sh"

# SSH params
export SSH_KEY_PATH="/home/ubuntu/.ssh/id_rsa"
export CLUSTER_USER="ubuntu"

# IPs
export MASTER_IP="10.0.4.47"
export SLAVE_IPS="10.0.4.47;10.0.4.29"

# Cluster params
export CLUSTER_PREFIX="etl"
export WORKER_NUMBER_PER_SLAVE=1
export WORKER_MEMORY=2G
export WORKER_CORES=1
export SPARK_IMAGE=maxnevermind/spark:2.2.0