Osmocom network in docker container - as simple as `docker compose up`

common feautures:
- connect limesdr and run `docker compose up` should work out of the box
- latest binary releases from osmocom repo
- configuration with single file `./configs/config.yml` (for most common parameters)
- automatic interaction with newly connected users
- egprs with routing
- active users monitoring and other useful scripts (see `./helpers`)

## gprs

DNS confirugration for default apn is in `./configs/dnsmasq/apn0.conf`

By default it resolves all domain names to localhost, since high mobile network traffic causes network degradation.

You can check who is currently using gprs with `./helpers/show-pdp.sh` or `./helpers/mon.sh`

You can also check the traffic on the apn0 interface with `./helpers/wireshark.sh`

## problems

- usrp support is not tested and may require additional configuration
- if MS leaves the network without detaching IMSI, it will be "active" for up to 8 minutes. This is because the minimum value for T3212 timer (location update) is 6 minutes, and MSC requires some time gap between T3212 value in BSC and MSC. Without gap, MSC may expire active subscribers.
- IPv6 routing not configured