# The configuration is based on the official documentation: https://nominatim.org/release-docs/latest/admin/Installation/
# and https://nominatim.org/release-docs/develop/appendix/Install-on-Ubuntu-22/

FROM ubuntu:jammy AS builder
LABEL maintainer Camptocamp "info@camptocamp.com"
SHELL ["/bin/bash", "-o", "pipefail", "-cux"]

# avoid interactive installation for tzdata

ENV NOMINATIM_VERSION=4.4.0
ENV NOMINATIM_TAR=Nominatim-${NOMINATIM_VERSION}.tar.bz2

# install dependencies
RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
    DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --assume-yes \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential wget bzip2 \
        cmake g++ libboost-dev libboost-system-dev \
        libboost-filesystem-dev libexpat1-dev zlib1g-dev \
        libbz2-dev libpq-dev liblua5.3-dev lua5.3 lua-dkjson \
        nlohmann-json3-dev postgresql-14-postgis-3 \
        postgresql-contrib-14 postgresql-14-postgis-3-scripts \
        libicu-dev python3-dotenv \
        python3-psycopg2 python3-psutil \
        python3-sqlalchemy python3-asyncpg \
        python3-icu python3-datrie python3-yaml python3-jinja2 \
        python3-pip

# installl python dependencies
WORKDIR /tmp
COPY requirements.txt ./
RUN python3 -m pip install -r requirements.txt

# get everything for nominatim
WORKDIR /nominatim

# FIXME --no-check-certificate is this needed? What is done in other imaes? perhaps add a certificate!
RUN wget -O ${NOMINATIM_TAR} https://nominatim.org/release/${NOMINATIM_TAR} --no-check-certificate \
    && tar xf ${NOMINATIM_TAR}

WORKDIR /nominatim/data

# FIXME this is probably needed in the DB so do not down load it here
# what is this file for?
# RUN wget -O country_osm_grid.sql.gz https://nominatim.org/data/country_grid.sql.gz --no-check-certificate

# build nominatim
WORKDIR /nominatim/build

RUN cmake /nominatim/Nominatim-${NOMINATIM_VERSION} \
    && make \
    && make install

FROM ubuntu:jammy AS runtime

WORKDIR /tmp
COPY requirements.txt ./

RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
    apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --assume-yes \
    && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends ca-certificates \
        dotenv \
        python3-psycopg2 \
        python3-psutil \
        python3-sqlalchemy \
        python3-asyncpg \
        python3-icu \
        python3-datrie \
        python3-yaml \
        python3-jinja2 \
        python3-pip \
        libexpat1 \
        zlib1g \
        liblua5.3 \
        lua5.3 \
        lua-dkjson \
        lua5.3 \
        postgresql-client \
    && export BOOST_VERSION=$(apt show libboost-all-dev | grep -i version | grep -oP 'Version: \K[0-9]+\.[0-9]+\.[0-9]+') \
    && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
        libboost-system${BOOST_VERSION} \
        libboost-filesystem${BOOST_VERSION} \
    && apt-get remove --assume-yes --purge build-essential linux-libc-dev \
    && python3 -m pip install -r requirements.txt \
    && python3 -m pip freeze > /requirements.txt

COPY --from=builder /usr/local/lib/nominatim /usr/local/lib/nominatim
COPY --from=builder /usr/local/bin/nominatim /usr/local/bin/nominatim
COPY --from=builder /usr/local/etc/nominatim/ /usr/local/etc/nominatim/
COPY --from=builder /usr/local/etc/nominatim/ /usr/local/etc/nominatim/
COPY --from=builder /usr/local/share/man/man1/nominatim.1 /usr/local/share/man/man1/nominatim.1
COPY --from=builder /usr/local/share/munin/plugins/ /usr/local/share/munin/plugins/
COPY --from=builder /usr/local/share/nominatim/ /usr/local/share/nominatim/

WORKDIR /usr/local/lib/nominatim/lib-python

EXPOSE 8080

# FIXME run the application with gunicorn but project the loct to the container logs
# CMD exec gunicorn -w 4 -k uvicorn.workers.UvicornWorker --bind 127.0.0.1:8080 "nominatim.server.falcon.server:run_wsgi()"
CMD [ "nominatim", "serve", "--server", "0.0.0.0:8080"]
