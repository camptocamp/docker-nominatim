# docker-nominatim
Docker image for running OSM Nominatim backend

## Create data base and Import data:

### Prerequisites:
- DB connection is correct in the in the environment variable `NOMINATIM_DATABASE_DSN`
- The web user (read only user) exists in the DB cluster `NOMINATIM_DATABASE_WEBUSER`
- The DB used for `nominatim` does **not** exist

To create the DB and import the data use:

```
nominatim import --osm-file <osm data file>
```

## Update existing date or import further data

### Prerequisites:
- The DB has to exist and the is accessible under the value definde for the env variable `NOMINATIM_DATABASE_DSN`

Run the command

```
#load the data
nominatim add-data --file <osm data file>
# rerun the index
nominatim index
```
