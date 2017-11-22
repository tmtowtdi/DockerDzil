
# tmtowtdi/distzilla
Docker container with build tools already installed, intended to reduce CI 
build times.

# Projects
The document you're reading right now gets used as the README on both Github 
and Docker Hub.  So whichever of those sites you're at, here's the link to the 
other site:

- [Github](https://github.com/tmtowtdi/DockerDzil)
- [Docker Hub](https://hub.docker.com/r/tmtowtdi/distzilla/)

# Automated Build

## Tracked Tags
Docker Hub watches for updates to specific git tags, and automatically builds 
new Docker images.

Right now, Dockerhub is watching for changes to these tags:

Git Tag Name | Docker Image Tag
--- | ---
latest | latest
v5.26 | 5.26
v5.24 | 5.24
v5.22.4 | 5.22.4
v5.14.4 | 5.14.4

`Dist::Zilla` requires perl 5.14 or later, so no use going any lower than 
that.

The Docker Hub project has also been linked to the official perl image project 
on Docker Hub.  Changes to that perl project should trigger a new build on 
this project.


## Update existing perl version/tag

- Delete the tag both locally and on github
    - delete local tag - `git tag -d v9.99`
    - delete tag on github - `git push --delete origin v9.99`
- Make your changes, commit them to master, re-tag
    - `git add -A . && git commit -m 'commit msg'` -- derp.
    - `git tag -a v9.99 -m "updating version 9.99"`
- Remember to push your new tag
    - `git push origin --tags`

## Create new automated build for a new perl version

- Create a new Dockerfile
    - Just copy from `Dockerfile.latest`.  Edit your new file and 
      `s/latest/<perl image version number to pull from>/`
- Update Docker Hub to start looking for your new tag
    - On the Docker Hub project, Build Settings tab, add a new entry following 
      existing examples.
        - The green `+` next to the first row adds a new row.
        - Click the 'Save Changes' button you nincompoop.
- Create a new git tag and push the tag to github
    - `git tag -a v9.99 -m 'initial 9.99 tag'` - Obviously, update the version 
      number.
    - `git push origin --tags`

## Build time
The automated builds on Docker Hub take way longer than they take locally.  If 
you've only got one build queued up, it can take around 20 minutes.  The "log" 
section at the bottom of the build details page on Docker Hub never shows me 
anything at all, but the builds *do* work.

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

