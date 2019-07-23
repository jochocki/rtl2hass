#!/bin/sh
rtl_433 -F mqtt://mqtt.ad.ochocki.org -M utc | python /scripts/rtl_433_mqtt_hass.py