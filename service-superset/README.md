# Service Superset

This docker compose file runs local Superset instance. In addition, Postgres database with demo data is started up.

Superset UI is accessible at [http://localhost:8088/](). The `ADMIN` user is created. Use following credentials
to log in to Superset:

* Username: `admin`
* Password: `admin`

In order to connect to Postgres instance with demo data, create a connection with following details:

* Host: `db-demo-data`
* Port: `5432`
* Database: `demo`
* Username: `demo`
* Password: `demo`