FROM python:3 AS intermediate

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
  && rm -rf /var/lib/apt/lists/*

#
# Pull RTL_433 source code from GIT, compile it and install it
#
WORKDIR /rtl_433 
RUN git clone https://github.com/merbanan/rtl_433.git . \
  && mkdir build \
  && cd build \
  && cmake ../ \
  && make \
  && make install



# Final image build
FROM python:3 AS final

#
# Define environment variables
# 
# Use this variable when creating a container to specify the MQTT broker host.
ENV MQTT_HOST ""
ENV MQTT_PORT 1883
ENV MQTT_USERNAME ""
ENV MQTT_PASSWORD ""
ENV MQTT_TOPIC rtl_433
ENV DISCOVERY_PREFIX homeassistant
ENV DISCOVERY_INTERVAL 600

RUN apt-get update && apt-get install --no-install-recommends -y \
  libtool \
  libusb-1.0.0-dev \
  librtlsdr-dev \
  rtl-sdr \
  && rm -rf /var/lib/apt/lists/*

COPY --from=intermediate /usr/local/include/rtl_433.h /usr/local/include/rtl_433.h
COPY --from=intermediate /usr/local/include/rtl_433_devices.h /usr/local/include/rtl_433_devices.h
COPY --from=intermediate /usr/local/bin/rtl_433 /usr/local/bin/rtl_433
COPY --from=intermediate /usr/local/etc/rtl_433 /usr/local/etc/rtl_433

#
# Install Paho-MQTT client
#
RUN pip3 install paho-mqtt

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