FROM ubuntu:bionic

COPY . /root

RUN apt-get update
RUN apt-get install -y git locales \
		&& rm -rf /var/lib/apt/lists/*

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
 && locale-gen en_US.UTF-8

WORKDIR /app

ENTRYPOINT bash /root/gh-jack $@
