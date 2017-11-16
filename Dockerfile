FROM perl:latest
RUN apt-get update \
    && apt-get install -y build-essential \
    && cpan install App::cpanminus 
RUN cpanm install Dist::Zilla \
    && cpanm install Test2::V0
