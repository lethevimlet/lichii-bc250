#!/bin/bash
L=$1; cd ~/oot-bc250-tests; rm -f /tmp/nx2-timeline-go
until [ -f shot-$L-start.png ]; do sleep 1; done; sleep 12; touch /tmp/nx2-timeline-go
