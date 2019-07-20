#
# Docker file to create an image that contains enough software to listen to events on the 433,92 Mhz band,
# filter these and publish them to a MQTT broker.
#
# The script resides in a volume and should be modified to meet your needs.
#
# The example script filters information from weather stations and publishes the information to topics that
# Domoticz listens on.
#
# Special attention is required to allow the container to access the USB device that is plugged into the host.
# The container needs priviliged access to /dev/bus/usb on the host.
# 
# docker run --name rtl_433 -d -e MQTT_HOST=<mqtt-broker.example.com>   --privileged -v /dev/bus/usb:/dev/bus/usb  <image>

FROM python:3.7-alpine

LABEL Description="This image is used to start a script that will monitor for events on 433,92 Mhz" Vendor="MarCoach" Version="1.0"
LABEL Maintainer="Jordan Ochocki"

#
# Define environment variables
# 
# Use this variable when creating a container to specify the MQTT broker host.
ENV MQTT_HOST ""
ENV MQTT_PORT 1883
ENV MQTT_TOPIC rtl_433/+/events
ENV DISCOVERY_PREFIX homeassistant
ENV DISCOVERY_INTERVAL 600

#
# First install software packages needed to compile RTL-SDR and rtl_433
#
RUN apk update && apk add --no-cache \
  git \
  musl-dev \
  gcc \
  make \
  cmake \
  pkgconf \
  libusb-dev
#  automake \
#  libtool \

#
# Install Paho-MQTT client
#
RUN pip install paho-mqtt

#
# Pull RTL-SDR source code from GIT, compile it and install it
#
WORKDIR ~/
RUN git clone git://git.osmocom.org/rtl-sdr.git \
  && cd rtl-sdr/ \
  && mkdir build \
  && cd build \
  && cmake ../ -DDETACH_KERNEL_DRIVER=ON \
  && make \
  && make install

#
# Pull RTL_433 source code from GIT, compile it and install it
#
WORKDIR ~/
RUN git clone https://github.com/merbanan/rtl_433.git \
  && cd rtl_433/ \
  && mkdir build \
  && cd build \
  && cmake ../ \
  && make \
  && make install

#
# Blacklist kernel modules for RTL devices
#
COPY rtl.blacklist.conf /etc/modprobe.d/rtl.blacklist.conf

#
# Copy scripts, make executable
#
COPY rtl_433_mqtt_hass.py /scripts/rtl_433_mqtt_hass.py
COPY entry.sh /scripts/entry.sh

RUN chmod +x /scripts/entry.sh

#
# Execute entry script
#
ENTRYPOINT [ "/scripts/entry.sh" ]