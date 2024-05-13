# TODO this is just a starting point. Needs proper configuration and testing
# The configuration is based on the official documentation: https://nominatim.org/release-docs/latest/admin/Installation/
# and https://nominatim.org/release-docs/develop/appendix/Install-on-Ubuntu-22/

FROM ubuntu:jammy AS build

# TODO set essential env valiables through .env file and read this

# avoit interactiv installation for tzdata
ENV DEBIAN_FRONTEND=noninteractive
ENV NOMINATIM_VERSION=4.4.0
ENV NOMINATIM_TAR=Nominatim-${NOMINATIM_VERSION}.tar.bz2

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
        python3-pip

# installl python dependencies
WORKDIR /tmp
COPY requirements.txt ./
RUN python3 -m pip install -r requirements.txt

# get everithing for nominatim
WORKDIR /nominatim

# TODO make shure that the URL is available
# FIXME --no-check-certificate is this needed?
RUN wget -O ${NOMINATIM_TAR} https://nominatim.org/release/Nominatim-4.4.0.tar.bz2 --no-check-certificate \
    && tar xf ${NOMINATIM_TAR}

WORKDIR /nominatim/data
# FIXME --no-check-certificate is this needed? -> this is probably neede in the DB so do not down load it here
RUN wget -O country_osm_grid.sql.gz https://nominatim.org/data/country_grid.sql.gz --no-check-certificate

# build nominatim
WORKDIR /nominatim/build

# FIXME BOOST deprecation waring?
RUN cmake /nominatim/Nominatim-${NOMINATIM_VERSION} \
    && make \
    && make install

# TODO clean up
    # apt-get clean \
    # rm -rf /var/lib/apt/lists/

EXPOSE 8080

# cd /usr/local/lib/nominatim/lib-python
# gunicorn -w 4 -k uvicorn.workers.UvicornWorker --bind 127.0.0.1:8080 "nominatim.server.falcon.server:run_wsgi()"
WORKDIR /usr/local/lib/nominatim/lib-python
CMD exec gunicorn -w 4 -k uvicorn.workers.UvicornWorker --bind 127.0.0.1:8080 "nominatim.server.falcon.server:run_wsgi()"


# TODO remove/replace this. It is just for dev - building and testing
# ENTRYPOINT ["tail", "-f", "/dev/null"]