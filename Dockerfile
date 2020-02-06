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

FROM debian:stretch AS intermediate

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
  python-setuptools \
  python-wheel \
  python-pip \
  && rm -rf /var/lib/apt/lists/*

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
# Cleanup
#
#RUN apt-get purge -y \
#  git \
#  build-essential \
#  autoconf \
#  cmake \
#  pkg-config \
#  && apt-get autoremove -y \
#  && rm -r /~/rtl_433

FROM debian:stretch AS final

#
# Define environment variables
# 
# Use this variable when creating a container to specify the MQTT broker host.
ENV MQTT_HOST ""
ENV MQTT_PORT 1883
ENV MQTT_USERNAME ""
ENV MQTT_PASSWORD ""
ENV MQTT_TOPIC rtl_433/+/events
ENV DISCOVERY_PREFIX homeassistant
ENV DISCOVERY_INTERVAL 600

RUN apt-get update && apt-get install --no-install-recommends -y \
  libtool \
  libusb-1.0.0-dev \
  librtlsdr-dev \
  rtl-sdr \
  python \
  python-setuptools \
  python-wheel \
  python-pip \
  && rm -rf /var/lib/apt/lists/*

COPY --from=intermediate /usr/local/include/rtl_433.h /usr/local/include/rtl_433.h
COPY --from=intermediate /usr/local/include/rtl_433_devices.h /usr/local/include/rtl_433_devices.h
COPY --from=intermediate /usr/local/bin/rtl_433 /usr/local/bin/rtl_433
COPY --from=intermediate /usr/local/etc/rtl_433 /usr/local/etc/rtl_433

#
# Install Paho-MQTT client
#
RUN pip install paho-mqtt

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
# Execute entry script
#
ENTRYPOINT [ "/scripts/entry.sh" ]