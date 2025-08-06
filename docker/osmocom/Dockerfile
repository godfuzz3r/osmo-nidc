# after debian 11 there is no asterisk package, using 11 so no need to compile
FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt install -y  wget \
                    iproute2 iptables dnsmasq \
                    tmux telnet tcpdump curl inetutils-ping procps netcat-traditional \
                    jq python3-argcomplete python3-tomlkit python3-xmltodict python3-yaml \
                    uhd-host

RUN wget https://ftp.debian.org/debian/pool/main/y/yq/yq_3.4.3-2_all.deb -O /tmp/yq_3.4.3-2_all.deb && \
    dpkg -i /tmp/yq_3.4.3-2_all.deb

RUN wget https://obs.osmocom.org/projects/osmocom/public_key && \
    mv public_key /etc/apt/trusted.gpg.d/osmocom.asc && \
    export OSMOCOM_REPO="https://downloads.osmocom.org/packages/osmocom:/latest/Debian_11" && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/osmocom.asc] $OSMOCOM_REPO/ ./" | tee /etc/apt/sources.list.d/osmocom-latest.list

RUN apt update && \
    apt install -y  osmo-trx-lms osmo-trx-uhd \
                    osmo-bts-trx osmo-bsc osmo-msc osmo-hlr \
                    osmo-stp osmo-pcu \
                    osmo-sgsn osmo-ggsn \
                    osmo-cbc osmo-cbc-utils \
                    osmo-sip-connector libsofia-sip-ua-glib-dev asterisk \
    && rm -rf /var/lib/apt/lists/*

RUN uhd_images_downloader

ENV UHD_IMAGES_DIR=/usr/share/uhd/images/

ENTRYPOINT ["nice", "-n", "-20", "bash", "/configs/entrypoint.sh"]
