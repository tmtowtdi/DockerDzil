#!/bin/bash

docker push tmtowtdi/distzilla:latest
docker rmi -f tmtowtdi/distzilla:latest
