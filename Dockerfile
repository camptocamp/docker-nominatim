# The configuration is based on the official documentation: https://nominatim.org/release-docs/latest/admin/Installation/
# and https://nominatim.org/release-docs/develop/appendix/Install-on-Ubuntu-22/

FROM ubuntu:jammy AS build

# avoid interactiv installation for tzdata
ENV DEBIAN_FRONTEND=noninteractive

ENV NOMINATIM_VERSION=4.4.0
ENV NOMINATIM_TAR=Nominatim-${NOMINATIM_VERSION}.tar.bz2

# install dependencies
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential wget bzip2 \
        cmake g++ libboost-dev libboost-system-dev \
        libboost-filesystem-dev libexpat1-dev zlib1g-dev \
        libbz2-dev libpq-dev liblua5.3-dev lua5.3 lua-dkjson \
        nlohmann-json3-dev postgresql-14-postgis-3 \
        postgresql-contrib-14 postgresql-14-postgis-3-scripts \
        libicu-dev python3-dotenv \
        python3-psycopg2 python3-psutil \
        python3-sqlalchemy python3-asyncpg \
        python3-icu python3-datrie python3-yaml python3-jinja2 \
        python3-pip \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/

# installl python dependencies
WORKDIR /tmp
COPY requirements.txt ./
RUN python3 -m pip install -r requirements.txt

# get everithing for nominatim
WORKDIR /nominatim

# FIXME --no-check-certificate is this needed? What is done in other imaes? perhaps add a certificate!
RUN wget -O ${NOMINATIM_TAR} https://nominatim.org/release/${NOMINATIM_TAR} --no-check-certificate \
    && tar xf ${NOMINATIM_TAR}

WORKDIR /nominatim/data

# FIXME this is probably neede in the DB so do not down load it here
# what is this file for?
# RUN wget -O country_osm_grid.sql.gz https://nominatim.org/data/country_grid.sql.gz --no-check-certificate

# build nominatim
WORKDIR /nominatim/build

RUN cmake /nominatim/Nominatim-${NOMINATIM_VERSION} \
    && make \
    && make install

EXPOSE 8080
COPY entrypoint.sh /usr/bin/entrypoint.sh

WORKDIR /usr/local/lib/nominatim/lib-python

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

# FIXME run the application with gunicorn but project the loct to the container logs
# CMD exec gunicorn -w 4 -k uvicorn.workers.UvicornWorker --bind 127.0.0.1:8080 "nominatim.server.falcon.server:run_wsgi()"
CMD [ "nominatim", "serve", "--server", "0.0.0.0:8080"]