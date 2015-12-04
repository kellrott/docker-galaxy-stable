#!/bin/bash

cd /galaxy-central
service postgresql start
./run.sh --daemon