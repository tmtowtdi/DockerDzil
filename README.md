
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
--- | ---
master | latest
v5.26 | 5.26
v5.24 | 5.24
v5.10.1 | 5.10.1

The Docker Hub project has also been linked to the official perl image project 
on Docker Hub.  Changes to that perl project should trigger a new build on 
this project.

To set up a new automated build:

- Create a new branch indicating the perl version.  Please name it with a 
  leading 'v' for consistency (eg `v5.24`)
- Check out your new branch.  Edit `Dockerfile` to pull the appropriate perl 
  image tag, eg `FROM perl:5.24`
- Visit [this project's Docker Hub 
  page](https://hub.docker.com/r/tmtowtdi/distzilla/), `Build Settings` tab.
    - Add a new row to the list of watched branches (the little green '+' 
      symbol next to the master branch row adds a new row).  Fill out your new 
      row as needed.
    - Click the 'Save Changes' button you nincompoop.

## Build time
The automated builds on Docker Hub take around 18 minutes, which is way longer 
than they take locally.  The "log" section at the bottom of the build details 
page on Docker Hub never shows me anything at all, but the builds *do* work.

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

Your Circle CI config file at `REPOROOT/.circleci/config` will look something 
like:
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

...So the gain here is that you don't have to waste Circle CI build minutes in 
building cpanm and Dist::Zilla with each build.

I don't see any reason this image couldn't be used for other CI tools.  Circle 
CI is just the only one I've tested it with.

# Problem with CircleCI
This problem has been fixed with the current Dockerfile, these are just notes 
so I can avoid making the same mistake next time.

Installing Perl modules via cpan or cpanm or cpm can cause a problem with UIDs 
that are too high for Docker to be able to map them.  This problem is not 
apparent when you build the image locally; it only shows up when CircleCI 
builds the image.  The error I get from them is:

```
CircleCI was unable to start the container because of a userns remapping failure in Docker.

This typically means the image contains files with UID/GID values that are higher than Docker and CircleCI can use.

Checkout our docs https://circleci.com/docs/2.0/high-uid-error/ to learn how to fix this problem.

Original error: failed to register layer: Error processing tar file(exit status 1): Container ID 831580115 cannot be mapped to a host ID
```

Files created by `cpan`, `cpanm`, and `cpm` can get assigned these high UIDs 
that confuse Docker.  Those files need to be removed or, at least, ownership 
on them needs to be changed to a lower UID (eg `root`):
```
### eelete
RUN cpm install -g Dist::Zilla && rm -rf /root/.perl-cpm
### or change ownership
RUN cpm install -g Dist::Zilla && chown -R root:root /root/.perl-cpm
```

Whether you change ownership on those build directories or just delete them 
entirely, *it must be done in the same RUN command that created those files*.  
This will not work:
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

