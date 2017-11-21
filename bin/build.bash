#!/bin/bash

docker build -t distzilla:latest - < Dockerfile
docker tag distzilla:latest tmtowtdi/distzilla:latest
docker rmi -f distzilla:latest
