# after debian 11 there is no asterisk package, using 11 so no need to compile
FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt install -y  wget \
                    iproute2 iptables dnsmasq \
                    tmux telnet tcpdump curl inetutils-ping procps netcat-traditional \
                    jq python3-argcomplete python3-tomlkit python3-xmltodict python3-yaml

RUN wget https://ftp.debian.org/debian/pool/main/y/yq/yq_3.4.3-1_all.deb -O /tmp/yq_3.4.3-1_all.deb && \
    dpkg -i /tmp/yq_3.4.3-1_all.deb

RUN wget https://obs.osmocom.org/projects/osmocom/public_key && \
    mv public_key /etc/apt/trusted.gpg.d/osmocom.asc && \
    export OSMOCOM_REPO="https://downloads.osmocom.org/packages/osmocom:/latest/Debian_11" && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/osmocom.asc] $OSMOCOM_REPO/ ./" | tee /etc/apt/sources.list.d/osmocom-latest.list

RUN apt update && \
    apt install -y  osmo-bts-trx osmo-bsc osmo-msc osmo-hlr \
                    osmo-stp osmo-pcu \
                    osmo-sgsn osmo-ggsn \
                    osmo-cbc osmo-cbc-utils \
                    osmo-sip-connector libsofia-sip-ua-glib-dev asterisk

# antsdr and osmo-trx-uhd build deps
RUN apt install -y --no-install-recommends \
                    autoconf automake libtool build-essential \
                    libboost-dev libosmocore-dev fftw3-dev \
                    ccache cmake cpufrequtils doxygen ethtool \
                    g++ git inetutils-tools libboost-all-dev \
                    libncurses5 libncurses5-dev libusb-1.0-0 \
                    libusb-1.0-0-dev libusb-dev python3-dev \
                    python3-mako python3-numpy python3-requests \
                    python3-scipy python3-setuptools python3-ruamel.yaml \
    && rm -rf /var/lib/apt/lists/*

# antsdr driver
RUN git clone https://github.com/MicroPhase/antsdr_uhd

RUN git clone https://gitea.osmocom.org/cellular-infrastructure/osmo-trx.git

WORKDIR /antsdr_uhd/host/

RUN mkdir ./build && \
    cd ./build && \
    cmake   -DENABLE_X400=OFF \
            -DENABLE_N320=OFF \
            -DENABLE_X300=OFF \
            -DENABLE_USRP2=OFF \
            -DENABLE_USRP1=OFF \
            -DENABLE_N300=OFF \
            -DENABLE_E320=OFF \
            -DENABLE_E300=OFF \
            ../ && \
    make -j$(nproc) && \
    make install && \
    ldconfig

WORKDIR /osmo-trx

RUN autoreconf -i && \
    ./configure --with-uhd && \
    make -j8 && \
    make install && \
    ldconfig

ENV UHD_IMAGES_DIR=/usr/share/uhd/images/

RUN uhd_images_downloader

ENTRYPOINT ["nice", "-n", "-20", "bash", "/configs/entrypoint.sh"]