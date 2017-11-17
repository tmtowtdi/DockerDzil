
# DockerDzil
Docker container with build tools already installed, intended to reduce CI 
build times.

# Tools
All of these live in `bin/`.

- build.bash
    - Builds 'dzil:latest' from ./Dockerfile
    - Re-tags the produced image as 'tmtowtdi/dzil:latest'
    - Removes the original 'dzil:latest'
        - This actually just removes the tag.  That removes it from the output 
          of `docker images` but doesn't remove the image itself, since 
          'dzil:latest' and 'tmtowtdi/dzil:latest' are just different tags 
          pointing at the same image.
    - If you want to produce a differently-tagged image, eg 
      "tmtowtdi/dzil:5.24a" to indicate perl v5.24.1:
        - Edit build.bash, Dockerfile, and push.bash
        - In all, `s/latest/5.24.1/g`.
- push.bash
    - Pushes 'tmtowtdi/dzil:latest' up to Dockerhub, then deletes the image 
      from the local store.
    - The local deletion is just to clean up when you're doing a bunch of 
      builds because you're currently working on the project.  You can comment 
      out that local deletion from the script if you want.
- connect.bash
    - Connects you to 'tmtowtdi/dzil:latest' in a bash shell
    - Remember to `set -o vi` first thing after you connect to save on the 
      expletives.

# Using with CircleCI
eg You have a git repo with a Dist::Zilla-controlled subdirectory that you 
want CircleCI to autobuild for you.

Assume your repo looks like this:
```
REPOROOT
  |- README.md
  |- .circleci/
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
       - image: tmtowtdi/dzil:latest
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

