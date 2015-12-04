#!/bin/bash

cd /galaxy-central
service postgresql stop
./run.sh --stop-daemon