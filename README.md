# DockerDzil
Docker container with build tools already installed, intended to reduce CI build times.

# Build
`docker build -t dzil:latest - < Dockerfile`
or
`docker build -t dzil:5.26 - < Dockerfile`
etc

# Branches and tags
Git branches are tied to Docker tags using Dockerhub's automated build setup.  
The convention I'm using:

Git Branch | Docker Tag
--- | ---
master | latest
v5.26 | 5.26

So to create a Docker tag for 5.24, create a git branch named 5.24 off master, 
edit the Dockerfile to `s/latest/5.24/`, and add [a new build 
setting](https://hub.docker.com/r/tmtowtdi/dockerdzil/~/settings/automated-builds/), 
following existing examples.

