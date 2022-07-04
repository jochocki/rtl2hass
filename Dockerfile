FROM python:3-alpine AS intermediate 

WORKDIR /rtl_433 

#
# First install software packages needed to compile RTL-SDR and rtl_433
#
RUN apk add --update-cache \
  git \
  libtool \
  libusb-dev \
  librtlsdr-dev \
  rtl-sdr \
  g++ \
  autoconf \
  cmake \
  make \
  pkgconfig \
  && rm -rf /var/lib/apt/lists/* \
  && git clone https://github.com/merbanan/rtl_433.git . \
  && mkdir build \
  && cd build \
  && cmake ../ \
  && make \
  && make install


# Final image build
FROM python:3-alpine AS final

#
# Define environment variables
# 
# Use this variable when creating a container to specify the MQTT broker host.
ENV MQTT_HOST "" \
    MQTT_PORT 1883 \
    MQTT_USERNAME "" \
    MQTT_PASSWORD "" \
    MQTT_TOPIC rtl_433 \
    DISCOVERY_PREFIX homeassistant \
    DISCOVERY_INTERVAL 600

RUN apk add --update-cache \
  libtool \
  libusb-dev \
  librtlsdr-dev \
  rtl-sdr \
  && pip3 install paho-mqtt

COPY --from=intermediate /usr/local/include/rtl_433.h /usr/local/include/rtl_433.h
COPY --from=intermediate /usr/local/include/rtl_433_devices.h /usr/local/include/rtl_433_devices.h
COPY --from=intermediate /usr/local/bin/rtl_433 /usr/local/bin/rtl_433
COPY --from=intermediate /usr/local/etc/rtl_433 /usr/local/etc/rtl_433

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

