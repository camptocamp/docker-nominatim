-- This script provides the basic skeleton for a DB used by Nominatim.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

CREATE ROLE nominatim WITH LOGIN PASSWORD 'nominatim';

-- Grant permissions to the nominatim user on the DB used by Nominatim
GRANT CREATE ON SCHEMA public TO nominatim;

-- Create a read-only user for for the DB used by Nominatim
CREATE USER rouser;

GRANT usage ON SCHEMA public TO rouser;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rouser;
