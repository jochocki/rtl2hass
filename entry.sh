#!/bin/sh
rtl_433 -F $MQTT_HOST -M utc | python /scripts/rtl_433_mqtt_hass.py