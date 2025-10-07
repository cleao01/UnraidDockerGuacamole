#!/bin/bash

REPOSITORY="cleao"

VERSION="$1"

docker build --rm -t "$REPOSITORY"/guacamole:"$VERSION" .

