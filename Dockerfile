FROM ruby:3.0.5-bullseye
MAINTAINER dtynan@kalopa.com

WORKDIR /app

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential software-properties-common ca-certificates apt-transport-https \
    curl git sudo dosfstools expect qemu-system-i386 \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
CMD ["/app/build.sh"]
