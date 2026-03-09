#!/bin/bash

REPOSITORY="cleao"

VERSION="beta"

docker build --rm -t "$REPOSITORY"/guacamole:"$VERSION" .

