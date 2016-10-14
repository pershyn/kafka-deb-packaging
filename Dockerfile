FROM debian:jessie

RUN apt-get update

RUN apt-get install -y wget openjdk-7-jdk ruby-dev gcc make

RUN gem install fpm

RUN mkdir /mnt/workdir
VOLUME /mnt/workdir
WORKDIR /mnt/workdir
