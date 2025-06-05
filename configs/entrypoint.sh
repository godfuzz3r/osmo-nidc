#!/bin/bash
### setup configs
cp /configs/osmocom/osmo-*.cfg /etc/osmocom/

sed "s@#mcc#@$(yq -rM '.network.mcc' /configs/config.yml)@g" -i /etc/osmocom/osmo-bsc.cfg
sed "s@#mcc#@$(yq -rM '.network.mcc' /configs/config.yml)@g" -i /etc/osmocom/osmo-msc.cfg

sed "s@#mnc#@$(yq -rM '.network.mnc' /configs/config.yml)@g" -i /etc/osmocom/osmo-bsc.cfg
sed "s@#mnc#@$(yq -rM '.network.mnc' /configs/config.yml)@g" -i /etc/osmocom/osmo-msc.cfg

sed "s@#short-name#@$(yq -rM '.network."short-name"' /configs/config.yml)@g" -i /etc/osmocom/osmo-msc.cfg
sed   "s@#long-name#@$(yq -rM '.network."long-name"' /configs/config.yml)@g" -i /etc/osmocom/osmo-msc.cfg
sed   "s@#encryption#@$(yq -rM '.network.encryption' /configs/config.yml)@g" -i /etc/osmocom/osmo-msc.cfg

if [[ $(yq -rM '.network."use-asterisk"' /configs/config.yml) = "true" ]]; then
    sed   "s@#use-asterisk#@@g" -i /etc/osmocom/osmo-msc.cfg
else 
    sed   "s@#use-asterisk#@!@g" -i /etc/osmocom/osmo-msc.cfg
fi

sed "s@#band#@$(yq -rM '.radio.band' /configs/config.yml)@g" -i /etc/osmocom/osmo-bsc.cfg
sed "s@#arfcn#@$(yq -rM '.radio.arfcn' /configs/config.yml)@g" -i /etc/osmocom/osmo-bsc.cfg
sed "s@#nominal-power#@$(yq -rM '.radio."nominal-power"' /configs/config.yml)@g" -i /etc/osmocom/osmo-bsc.cfg
sed "s@#max-power-red#@$(yq -rM '.radio."max-power-red"' /configs/config.yml)@g" -i /etc/osmocom/osmo-bsc.cfg

if [[ $(yq -rM '.radio."device-type"' /configs/config.yml) = "lime" ]]; then
    sed "s@#tx-path#@$(yq -rM '.radio."tx-path"' /configs/config.yml)@g" -i /etc/osmocom/osmo-trx-lms.cfg
    sed "s@#rx-path#@$(yq -rM '.radio."rx-path"' /configs/config.yml)@g" -i /etc/osmocom/osmo-trx-lms.cfg
elif [[ $(yq -rM '.radio."device-type"' /configs/config.yml) = "uhd" ]]; then
    cp /configs/uhd_images/*.bin /usr/share/uhd/images
    sed "s@#tx-path#@$(yq -rM '.radio."tx-path"' /configs/config.yml)@g" -i /etc/osmocom/osmo-trx-uhd.cfg
    sed "s@#rx-path#@$(yq -rM '.radio."rx-path"' /configs/config.yml)@g" -i /etc/osmocom/osmo-trx-uhd.cfg
    sed "s@#clock-ref#@$(yq -rM '.radio."clock-ref"' /configs/config.yml)@g" -i /etc/osmocom/osmo-trx-uhd.cfg
fi

sed "s@#apn-name#@$(yq -rM '.egprs."apn-name"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#type-support#@$(yq -rM '.egprs."type-support"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg

sed "s@#ip-prefix#@$(yq -rM '.egprs."ip-prefix"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#ip-ifconfig#@$(yq -rM '.egprs."ip-ifconfig"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#dns0#@$(yq -rM '.egprs.dns0' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#dns1#@$(yq -rM '.egprs.dns1' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg

sed "s@#ipv6-prefix#@$(yq -rM '.egprs."ipv6-prefix"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#ipv6-ifconfig#@$(yq -rM '.egprs."ipv6-ifconfig"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#dns0-v6#@$(yq -rM '.egprs."dns0-v6"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg
sed "s@#dns1-v6#@$(yq -rM '.egprs."dns1-v6"' /configs/config.yml)@g" -i /etc/osmocom/osmo-ggsn.cfg

sed "s@#msisdn-length#@$(yq -rM '.subscribers."msisdn-length"' /configs/config.yml)@g" -i /etc/osmocom/osmo-hlr.cfg

osmo-bsc -c /etc/osmocom/osmo-bsc.cfg &
osmo-msc -c /etc/osmocom/osmo-msc.cfg &
osmo-hlr -c /etc/osmocom/osmo-hlr.cfg &
osmo-mgw -c /etc/osmocom/osmo-mgw.cfg &
osmo-stp -c /etc/osmocom/osmo-stp.cfg &

osmo-sgsn -c /etc/osmocom/osmo-sgsn.cfg &
osmo-ggsn -c /etc/osmocom/osmo-ggsn.cfg &
osmo-pcu -c /etc/osmocom/osmo-pcu.cfg &

osmo-cbc -c /etc/osmocom/osmo-cbc.cfg &

if [[ $(yq -rM '.network."use-asterisk"' /configs/config.yml) = "true" ]]; then
    cp /configs/asterisk/sip.conf /etc/asterisk/sip.conf
    cp /configs/asterisk/extensions.conf /etc/asterisk/extensions.conf
    osmo-sip-connector -c /etc/osmocom/osmo-sip-connector.cfg &
    asterisk
fi

if [[ $(yq -rM '.radio."device-type"' /configs/config.yml) = "lime" ]]; then
    osmo-trx-lms -C /etc/osmocom/osmo-trx-lms.cfg &
elif [[ $(yq -rM '.radio."device-type"' /configs/config.yml) = "uhd" ]]; then
    osmo-trx-uhd -C /etc/osmocom/osmo-trx-uhd.cfg &
fi

# need wait before trx is initialized, else osmo-bts will crash
sleep 5
osmo-bts-trx -c /etc/osmocom/osmo-bts.cfg &



if [[ $(yq -rM '.egprs."routing-enabled"' /configs/config.yml) = "true" ]]; then
    # get output interface name
    iface=$(ip route show default | awk -F'dev ' '{ print $2 }')

    iptables -A FORWARD -i apn0 -o $iface -j ACCEPT
    iptables -A FORWARD -i $iface -o apn0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o $iface -j SNAT --to-source 172.16.80.10

    # TODO: ipv6 routing to internet
fi

# dns for APN resolve
nice -n 0 dnsmasq -C /configs/dnsmasq/sgsn.conf

# dns for devices that uses APN
nice -n 0 dnsmasq -C /configs/dnsmasq/apn0.conf

nice -n 19 sleep infinity
