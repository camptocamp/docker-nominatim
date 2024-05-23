# docker-nominatim

Docker image for running OSM Nominatim backend.

The Image contains a nominatim backend installation that can be used to add/update data into a dedicated DB as well as serve a nominatim API.
For detailed information see https://nominatim.org/release-docs/latest/ or the nominatim code https://github.com/osm-search/Nominatim

This image **does not** provide a DB. The DB/DB server must be provided separately.

All regular nominatim settings can be set through the `.env` file. For details and nominatim specific parameters see https://nominatim.org/release-docs/latest/customize/Settings/

**The image can be used:**

- run a nominatim API
- create and load data into a dedicated DB
- update a dedicated nominatim DB

## Filling the DB

### Create a DB and Import data

#### Prerequisites:

- DB connection is correctly configured under `NOMINATIM_DATABASE_DSN` in the `.env` file
- The user given in the connection above needs to be able to create a new DB (superuser)
- A web user (read only user) exists in the DB cluster, configured under `NOMINATIM_DATABASE_WEBUSER`. And has the following rights:
  ```sql
  GRANT usage ON SCHEMA public TO rouser;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO rouser;
  ```
- The DB used for `nominatim` does **not** yet exist

To create the DB and import the data use:

```bash
nominatim import --osm-file <osm data file>
```

This will create a new data base under the given connection. If the database already exists the command results in an error. Also this command requires supper user rights on the cluster so that a new data base can be created.

### Import data into an existing **empty** DB without superuser rights on the DB

#### Prerequisites:

- - DB connection is correctly configured under `NOMINATIM_DATABASE_DSN` in the `.env` file
- The user given in the connection above needs owner right on the public schema (he will create the structure used for nominatim)
  ```sql
  GRANT CREATE ON SCHEMA public TO nominatim;
  ```
- The web user (read only user) exists in the DB cluster `NOMINATIM_DATABASE_WEBUSER`the
  ```sql
  GRANT usage ON SCHEMA public TO rouser;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO rouser;
  ```
- The DB must exists with the following extensions activated:
  ```sql
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS hstore;
  CREATE EXTENSION IF NOT EXISTS postgis_raster
  ```

To create the necessary tables and import data run:

```
nominatim import --continue import-from-file --osm-file <osm data file>
```

This command will run all the necessary steps to have a functional nominatim DB except create a new DB

If this command returns an error after having create the DB tables re-start the import using a different flavour of `--continue`. For more options check `nominatim import --help`

### Update existing date or import further data

#### Note

Locally this tends to take much longer than importing data on setup.

#### Prerequisites:

- The DB has to exist and is accessible under the value defined for the env variable `NOMINATIM_DATABASE_DSN`
- The DB has to have the basic structure required for nominatim

Run the command

```
# load the data
nominatim add-data --file <osm data file>
# rerun the indexing
nominatim index
```
