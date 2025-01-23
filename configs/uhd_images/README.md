## custom uhd firmware

It's most commonly for USRP B200/B210 clones which uses different FPGA's. Place the custom firmware in ./configs/uhd_images/ and give it an appropriate name, such as usrp_b210_fpga.bin. It will be automatically placed in the /usr/share/uhd/images/ folder inside the osmocom container.

The example usage is LibreSDR B220 mini (XC7A100T+AD9361) which use cusom fpga firmware.
