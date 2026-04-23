FROM drakkan/sftpgo:latest

USER root

RUN apt-get update && apt-get install -y \
    bash \
    curl \
 && apt-get clean

COPY config/sftpgo.json /etc/sftpgo/sftpgo.json