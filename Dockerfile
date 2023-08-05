FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        gcc \
        python3-dev \
        libkrb5-dev \
        krb5-user \
        python3-pip \
        libxml2-dev \
        libxslt1-dev \
        libssh-dev \
        libssl-dev \
        net-tools \
    && pip3 install --upgrade pip virtualenv pywinrm[kerberos] ansible \
    && pip3 install junos-eznc jxmlease xmltodict \
    && ansible-galaxy collection install juniper.device \
    && ansible-galaxy collection install Juniper.junos \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY playbooks /etc/ansible/playbooks

COPY hosts /etc/ansible/hosts

COPY run.sh /etc/ansible/run.sh

WORKDIR /etc/ansible

ENTRYPOINT ["run.sh"]
