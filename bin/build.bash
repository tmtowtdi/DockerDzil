#!/bin/bash

docker build -t dzil:latest - < Dockerfile
docker tag dzil:latest tmtowtdi/dzil:latest
docker rmi -f dzil:latest
