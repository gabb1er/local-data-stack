# Service Datalens

This docker compose file runs local Datalens instance. In addition, Postgres database with demo data is started up.

Datalens UI is accessible at [http://localhost:8080/]().

In order to connect to Postgres instance with demo data, create a connection with following details:

* Host: `pg-data`
* Port: `5432`
* Database: `demo`
* Username: `demo`
* Password: `demo`