# plpgsql-semver2
SemVer 2.0.0 for PostgreSQL written in plpgsql

This library was written in plpgsql so as to minimize issues with adding SemVer support to PostgreSQL instances running in the cloud (e.g. AWS RDS, GCP CloudSQL).

## Considerations

### GCP CloudSQL

Almost everything works in CloudSQL except Operator Classes, which requires `superuser` access BUT is not available.

You will receive an error like the following

```
psql:/tmp/install-plpgsql-semver2.sql:385: ERROR:  must be superuser to create an operator class
```

Because Operator Classes cannot be installed in CloudSQL, you cannot create BTree and Hash Indexes on `semver` columns. This just means that filtering and sorting on `semver` columns will be slower.
