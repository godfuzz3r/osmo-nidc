# osmocom network in docker container

as simple as `docker compose up`

common feautures:
- latest binary releases from osmocom repo
- configuration with single file `./configs/config.yml` (for most common parameters)
- automatic interaction with newly connected users
- egprs with routing
- active users monitoring and other useful scripts (see `./helpers`)

## limesdr configuration

In `./config/config.yml` set `device-type` to `lime`, set appropriate `tx-path` and `rx-path`. BAND2 and LNAW are work on LimeSDR USB and LimeSDR Mini

## usrp b200/b210 configuration

In `./config/config.yml` set `device-type` to `uhd`, set appropriate `tx-path` and `rx-path`. TX/RX and TX/RX should work, but need testing.

## usrp b200/b210 clones configuration

Place the custom firmware in `./config/uhd_images/` and give it an appropriate name, such as usrp_b210_fpga.bin. It will be automatically placed in the `/usr/share/uhd/images/` folder inside the osmocom container.

In `./config/config.yml` set `device-type` to `uhd`, set `tx-path` and `rx-path` accordingly. TX/RX and TX/RX are work on libresdr b220 mini.

## gprs

DNS confirugration for default apn is in `./configs/dnsmasq/apn0.conf`

By default it resolves all domain names to localhost, since high mobile network traffic causes network degradation.

You can check who is currently using gprs with `./helpers/show-pdp.sh` or `./helpers/mon.sh`

You can also check the traffic on the apn0 interface with `./helpers/wireshark.sh`

## problems

- if MS leaves the network without detaching IMSI, it will be "active" for up to 8 minutes. This is because the minimum value for T3212 timer (location update) is 6 minutes, and MSC requires some time gap between T3212 value in BSC and MSC. Without gap, MSC may expire active subscribers.
- IPv6 routing not configured
