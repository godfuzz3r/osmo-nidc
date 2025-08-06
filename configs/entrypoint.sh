#!/bin/bash

cleanup() {
    echo "Container stopped, performing iptables cleanup..."
    iface=$(yq -rM '.egprs."output-interface"' /configs/config.yml)
    ip_prefix=$(yq -rM '.egprs."ip-prefix"' /configs/config.yml)

    iptables -D FORWARD -i apn0 -o "$iface" -j ACCEPT 2>/dev/null
    iptables -D FORWARD -i "$iface" -o apn0 -j ACCEPT 2>/dev/null
    iptables -t nat -D POSTROUTING -s "$ip_prefix" -o "$iface" -j MASQUERADE 2>/dev/null

    iptables -t nat -D PREROUTING -i apn0 -p tcp -j REDIRECT --to-ports 12346 2>/dev/null
}
trap 'cleanup' SIGTERM

# first we need determine which iptables used on the host: legacy or nf_tables
# taken from kubernetes https://github.com/kubernetes/kubernetes/blob/ffe93b3979486feb41a0f85191bdd189cbd56ccc/build/debian-iptables/iptables-wrapper
num_legacy_lines=$( (iptables-legacy-save || true; ip6tables-legacy-save || true) 2>/dev/null | grep '^-' | wc -l)
if [ "${num_legacy_lines}" -ge 10 ]; then
    mode=legacy
else
    num_nft_lines=$( (timeout 5 sh -c "iptables-nft-save; ip6tables-nft-save" || true) 2>/dev/null | grep '^-' | wc -l)
    if [ "${num_legacy_lines}" -ge "${num_nft_lines}" ]; then
    mode=legacy
    else
    mode=nft
    fi
fi

update-alternatives --set iptables "/usr/sbin/iptables-${mode}" > /dev/null
update-alternatives --set ip6tables "/usr/sbin/ip6tables-${mode}" > /dev/null

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
    sysctl -w net.ipv4.ip_forward=1

    iface=$(yq -rM '.egprs."output-interface"' /configs/config.yml)
    ip_prefix=$(yq -rM '.egprs."ip-prefix"' /configs/config.yml)

    iptables -D FORWARD -i apn0 -o "$iface" -j ACCEPT 2>/dev/null
    iptables -D FORWARD -i "$iface" -o apn0 -j ACCEPT 2>/dev/null
    iptables -t nat -D POSTROUTING -s "$ip_prefix" -o "$iface" -j MASQUERADE 2>/dev/null

    iptables -A FORWARD -i apn0 -o "$iface" -j ACCEPT
    iptables -A FORWARD -i "$iface" -o apn0 -j ACCEPT
    iptables -t nat -A POSTROUTING -s "$ip_prefix" -o "$iface" -j MASQUERADE

    # TODO: ipv6 routing to internet
fi

# dns for APN resolve
nice -n 0 dnsmasq -C /configs/dnsmasq/sgsn.conf

# dns for devices that uses APN
nice -n 0 dnsmasq -C /configs/dnsmasq/apn0.conf

nice -n 19 sleep infinity &

wait $!
cleanup