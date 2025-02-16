ARG TAG="4.4.2"

FROM  rocker/r-base:$TAG

RUN apt-get update
RUN apt-get install -y --no-install-recommends vim git
RUN apt-get install -y libxml2-dev libssl-dev libcurl4-openssl-dev libssh2-1-dev libfontconfig1-dev
RUN apt-get install -y libfreetype6-dev libglib2.0-dev libcairo2-dev
RUN apt-get install -y libharfbuzz-dev libfribidi-dev
RUN apt-get install -y libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev
RUN apt-get install -y pandoc qpdf

RUN mkdir settings

COPY install_packages.R /settings

RUN Rscript 'settings/install_packages.R'