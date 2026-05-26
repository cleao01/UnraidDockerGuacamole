#!/bin/bash

REPOSITORY="cleao"

VERSION="beta"

docker build -t "$REPOSITORY"/guacamole:"$VERSION" .


