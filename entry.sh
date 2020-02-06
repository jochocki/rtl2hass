#!/bin/sh
rtl_433 -F mqtt://$MQTT_HOST:$MQTT_PORT,user=$MQTT_USERNAME,pass=$MQTT_PASSWORD -M newmodel -M utc | python /scripts/rtl_433_mqtt_hass.py