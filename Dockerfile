FROM perl:latest
RUN apt-get update \
    && apt-get install -y build-essential \
    && cpan install App::cpanminus \
    && cpan install App::cpm
RUN cpm install Dist::Zilla \
    && cpm install Test2::V0
