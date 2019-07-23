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

FROM debian:stretch

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
RUN apt-get update && apt-get install --no-install-recommends -y \
  git \
  libtool \
  libusb-1.0.0-dev \
  librtlsdr-dev \
  rtl-sdr \
  build-essential \
  autoconf \
  cmake \
  pkg-config \
  python \
  python-pip \
  && rm -rf /var/lib/apt/lists/*

#
# Install Paho-MQTT client
#
RUN pip install paho-mqtt

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
COPY entry.sh rtl_433_mqtt_hass.py /scripts/
RUN chmod +x /scripts/entry.sh

#
# Cleanup
#
RUN apt-get remove --purge \
  git \
  build-essential \
  autoconf \
  cmake \
  pkg-config \
  && rm -r ~/rtl_433

#
# Execute entry script
#
ENTRYPOINT [ "/scripts/entry.sh" ]