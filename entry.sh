#!/bin/bash
rtl_433 -R 40 -F json | python /scripts/rtl_433_mqtt_hass.py