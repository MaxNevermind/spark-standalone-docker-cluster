
# Description:

This project can be used for creating Spark standalone cluster on Docker. It includes a docker file for creating 
a Spark Docker container and a deployment script.

# Deployment on a cloud
- Set deployment config env variables. You can find an example of how to properly set them in a file(`deploy-config.sh`).
- Run a deployment script(`deploy.sh`) 

## Prerequisites:
- Docker is has to be installed on cluster machines.
- You need password-less SSH login to each of the machines in a cluster from a deployment machine.

If you want to use OracleJDK there is Dockerfile-OracleJDK file which you can use. I didn't want to use it because, as I understand, the current license of OracleJDK doesn't allow to distribute it inside a docker container build on Linux.
