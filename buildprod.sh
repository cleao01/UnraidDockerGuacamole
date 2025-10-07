#!/bin/bash

REPOSITORY="cleao"

VERSION="1.0.2"

docker build --rm -t "$REPOSITORY"/guacamole:"$VERSION" .
docker image tag cleao/guacamole:"$VERSION" cleao/guacamole
