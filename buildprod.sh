#!/bin/bash

REPOSITORY="cleao"

VERSION="1.0.4"

docker build -t "$REPOSITORY"/guacamole:"$VERSION" .
docker image tag cleao/guacamole:"$VERSION" cleao/guacamole
