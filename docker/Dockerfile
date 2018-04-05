FROM openjdk:8

USER root

WORKDIR /usr/share/
RUN cd /usr/share/

# Install Utils
RUN apt-get update -y
RUN apt-get install -y vim
RUN apt-get install -y curl
RUN apt-get install -y wget

# Install Spark
RUN wget https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
RUN tar -zxvf spark-2.2.0-bin-hadoop2.7.tgz
RUN mv spark-2.2.0-bin-hadoop2.7 spark
ENV PATH $PATH:/usr/share/spark/bin

# Create Spark logging dirictories & add spark-defaults.conf
ADD ./resources/log4j.properties /usr/share/spark/conf/
ADD ./resources/spark-defaults.conf /usr/share/spark/conf/

# Clean up
RUN rm -rf *tgz
RUN rm -rf *deb
