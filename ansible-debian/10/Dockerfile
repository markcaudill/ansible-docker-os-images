FROM debian:10
LABEL maintainer="Mark Caudill <mark@mrkc.me>"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		python3-apt \
		python3-pip \
		sudo && \
	apt-get clean  && \
    rm -rf /var/lib/apt/lists/*
