FROM debian:wheezy

RUN apt-get update

RUN apt-get install -y wget openjdk-7-jdk

RUN mkdir /mnt/workdir
VOLUME /mnt/workdir
WORKDIR /mnt/workdir
