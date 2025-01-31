# osmocom network in docker container

as simple as `docker compose up`

common feautures:
- latest binary releases from osmocom repo
- configuration with single file `./configs/config.yml` (for most common parameters)
- automatic interaction with newly connected users
- egprs with routing
- active users monitoring and other useful scripts (see `./helpers`)

## limesdr configuration

In `./config/config.yml` set values in `radio` section:
```yml
...
radio:
  ...
  device-type: lime
  tx-path: BAND2
  rx-path: LNAW
  ...
```
BAND2 and LNAW do work on LimeSDR USB and LimeSDR Mini

## usrp b200/b210 configuration

In `./configs/config.yml` set values in `radio` section:
```yml
...
radio:
  ...
  device-type: uhd
  tx-path: TX/RX
  rx-path: TX/RX
  clock-ref: external
  ...
```
TX/RX and TX/RX should work, but need testing. You can also set external/internal/gpsdo clock-ref for usrp devices:
- external - ext 10 mhz ref clock, such as leo godnar/octoclock gpsdo
- internal - default usrp's clock
- gpsdo    - internal gpsdo that maunted in usrp board (if any)

Feel free to check offisial osmo-trx-uhd documentation, 1.10.4 clock-ref: https://ftp.osmocom.org/docs/osmo-trx/master/osmotrx-uhd-vty-reference.pdf

## usrp b200/b210 clones configuration

Place the custom firmware in `./configs/uhd_images/` and give it an appropriate name, such as usrp_b210_fpga.bin. It will be automatically placed in the `/usr/share/uhd/images/` folder inside the osmocom container. It's useful for devices such as USRP B210 LibreSDR clones.

In `./configs/config.yml` set values in `radio` section:
```yml
...
radio:
  ...
  device-type: uhd
  tx-path: TX/RX
  rx-path: TX/RX
  clock-ref: external
  ...
```
TX/RX and TX/RX do work on LibreSDR B220 mini (XC7A100T+AD9361). You can also set external/internal/gpsdo clock-ref for such devices:
- external - ext 10 mhz ref clock. Tested with leo bodnar gpsdo
- internal - default onboard clock, in my testbed it was too poor to get gsm work properly

## gprs

DNS confirugration for default apn is in `./configs/dnsmasq/apn0.conf`

By default it resolves all domain names to localhost, since high mobile network traffic causes network degradation.

You can check who is currently using gprs with `./helpers/show-pdp.sh` or `./helpers/mon.sh`

You can also check the traffic on the apn0 interface with `./helpers/wireshark.sh`

## problems

- if MS leaves the network without detaching IMSI, it will be "active" for up to 8 minutes. This is because the minimum value for T3212 timer (location update) is 6 minutes, and MSC requires some time gap between T3212 value in BSC and MSC. Without gap, MSC may expire active subscribers.
- IPv6 routing not configured
- sometimes devices may be not properly "passed" to container. Stop container, reconnect device and start container again may help

## todo
- silent call/paging interaction
- setup default values if some fields in `./configs/config.yml` does not exists (for now deleting field from config.yml would cause crash)
