
# tmtowtdi/distzilla
Docker container with build tools already installed, intended to reduce CI 
build times.

# Automated Build

## Tracked Branches
[This project](https://hub.docker.com/r/tmtowtdi/distzilla/builds/) on Docker 
Hub watches for pushes to this git repo, and automatically builds new Docker 
images.  Any push to a branch specified on the Build Settings tab on Docker 
Hub will trigger a new build.

Right now, Dockerhub is watching for changes to these branches/tags:

Git Branch Name | Docker Image Tag
=== | ===
master | latest
v5.26 | 5.26

The Docker Hub project has also been linked to the official perl image project 
on Docker Hub.  Changes to that perl project should trigger a new build on 
this project.

## Build time
Takes around 18 minutes, which is way longer than it takes locally.  The "log" 
section at the bottom of the build details page never shows me anything at 
all, but the build does appear to work.

# Tools
These are not required for initiating a build on Docker Hub.  They're just 
handy for working locally.

- `bin/build.bash`
    - Builds 'tmtowtdi/distzilla:latest' from ./Dockerfile
- `bin/connect.bash`
    - Connects you to 'tmtowtdi/distzilla:latest' in a bash shell
    - Remember to `set -o vi` first thing after you connect to save on the 
      expletives.

# Using with CircleCI
Assuming you have a git repo with a Dist::Zilla-controlled subdirectory that 
you want CircleCI to autobuild for you, and your repo looks something like 
this:
```
REPOROOT
  |- README.md
  |- .circleci/
      |- config.yml
  |
  |- Whatever other stuff you keep in your repo that's not Dist::Zilla-related
  |
  |- dz/
      |- dist.ini
      |- bin/
      |- lib/
      |- t/
```

`REPOROOT/.circleci/config`:
```
 version: 2
 jobs:
   build:
     docker:
       - image: tmtowtdi/distzilla:latest
     steps:
       - checkout
       - run:
           name: Install with dzil
           pwd: dz
           command: dzil install

```

# Problem with CircleCI
This problem has been fixed with the current Dockerfile, these are just notes 
so I can avoid making the same mistake next time.

Installing Perl modules via cpan or cpanm or cpm can cause a problem with UIDs 
that are too high for Docker to be able to map them.  This problem is not 
apparent when you build the image locally, but it does show up when CircleCI 
pulls the image.  The error I get from them is:

```
CircleCI was unable to start the container because of a userns remapping failure in Docker.

This typically means the image contains files with UID/GID values that are higher than Docker and CircleCI can use.

Checkout our docs https://circleci.com/docs/2.0/high-uid-error/ to learn how to fix this problem.

Original error: failed to register layer: Error processing tar file(exit status 1): Container ID 831580115 cannot be mapped to a host ID
```

Long story short, what you need to do in that case is to, in your Dockerfile, 
install your module and then remove the offending build files all in the same 
command, eg:
```
RUN cpm install -g Dist::Zilla && rm -rf /root/.perl-cpm
```

Alternately, you could recursively change ownership on those directories 
instead of deleting them:
```
RUN cpm install -g Dist::Zilla && chown -R root:root /root/.perl-cpm
```

Whether you change ownership on those build directories or just delete them 
entirely, it must be done in a single RUN command; this will not work, because 
the first RUN command will complete with those mis-owned files in existence, 
and that's what causes the CircleCI error.
```
RUN cpm install -g Dist::Zilla
RUN chown -R root:root /root/.perl-cpm
```

Where do different build tools leave their files?

Tool | Location
--- | ---
cpan | /root/.cpan
cpanm | /root/.cpanm
cpm | /root/.perl-cpm

