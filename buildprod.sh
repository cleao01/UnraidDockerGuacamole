#!/bin/bash

REPOSITORY="cleao"

VERSION="1.0.6"

docker build -t "$REPOSITORY"/guacamole:"$VERSION" .
docker image tag cleao/guacamole:latest cleao/guacamole
