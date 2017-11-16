# DockerDzil
Docker container with build tools already installed, intended to reduce CI build times.

# Build
`docker build -t dzil:5.26 - < Dockerfile` 

Above, `5.26` is the tag for both the perl image in the Dockerfile and the 
image we're creating.  Change it as you change perl images.

