#!/bin/sh
rtl_433 -F mqtt://$MQTT_HOST:$MQTT_PORT -M newmodel -M utc | python /scripts/rtl_433_mqtt_hass.py