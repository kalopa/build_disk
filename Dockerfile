FROM ubuntu:latest

WORKDIR /app

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential software-properties-common ca-certificates apt-transport-https \
    curl git sudo ruby-rubygems expect qemu-system-x86 \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
CMD ["/app/build.sh"]
