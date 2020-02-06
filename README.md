# rtl2hass

This is source code for a Docker image that will receive 433.92 MHz sensor data (Acurite, etc) and pass it to Home Assitant using MQTT. Setup to work with Home Assistant's MQTT Discovery module.

Pre-built Docker image built at https://hub.docker.com/r/jochocki/rtl2hass

rtl_433 project can be found here: https://github.com/merbanan/rtl_433

`rtl_433_mqtt_hass.py` sourced from example script: https://github.com/merbanan/rtl_433/blob/master/examples/rtl_433_mqtt_hass.py

## Requirements

### DVB-T Receiver
A USB DVB-T dongle is required to use this container.

You must pass your USB DVB-T dongle to the container, as well as blacklist the kernel modules from your host.

#### To find the device location of your dongle, run:
```
lsusb
```

Sample output:
```
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 003: ID 8087:0a2b Intel Corp. 
Bus 001 Device 004: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T # This is your DVB-T dongle
Bus 001 Device 002: ID 0658:0200 Sigma Designs, Inc. 
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

Example device location would be `/dev/bus/usb/001/004`

#### To blacklist the kernel modules on your host, run the following:
```
wget -O rtl.blacklist.conf https://raw.githubusercontent.com/jochocki/rtl2hass/master/rtl.blacklist.conf
sudo cp rtl.blacklist.conf /etc/modprobe.d/rtl.blacklist.conf
```
### Home Assistant configuration

See https://www.home-assistant.io/docs/mqtt/discovery/

## Environment variables:
```
MQTT_HOST
MQTT_PORT (default value: 1883)
MQTT_USERNAME (if required)
MQTT_PASSWORD (if required)
MQTT_TOPIC (default value: rtl_433/+/events)
DISCOVERY_PREFIX (default value: homeassistant)
DISCOVERY_INTERVAL (default value: 600)
```

* MQTT_HOST has no default value - supply the hostname or IP of your MQTT broker
* DISCOVERY_PREFIX should match the `discovery_prefix:` setting in your Home Assistant MQTT config
* DISCOVERY_INTERVAL is how often (in seconds) events are sent to Home Assistant

## Sample docker run command:
```
docker run -d --name=rtl2hass --device=/dev/bus/usb/001/004 --env MQTT_HOST=mqtt.example.com jochocki/rtl2hass
```

## Sample docker compose file:
```
version: '2'

services:
  rtl2hass:
    container_name: rtl2hass
    image: jochocki/rtl2hass
    devices:
     - "/dev/bus/usb/001/004"
    environment:
      - MQTT_HOST=mqtt.example.com
```
