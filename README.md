# Local Data Stack
## Architecture
![Architecrtural](/docs/architecture.png)

## Installation

The project is origanized inside the `docker-compose.yml`, but it's highly advised to follow these steps:
1. Start `airflow-init` with `docker compose up airflow-init`
2. Start everything else with `docker compose up`
3. Create a `reports` bucket
   * You can use your IDE or all relevant tool. ![bucket](/docs/create_bucket.png)
   * Minio is working at `http://minio:9000` or at localhost. Credentials are `minioadmin` for password and username
4. Add connections to Apache Airflow
   * clickhouse_default
   * postgres_default
   * minio_default:
     * <code>{
       "aws_access_key_id": "minioadmin",
       "aws_secret_access_key": "minioadmin",
       "host": "http://minio:9000"
       }</code>
     * ![minio](/docs/minio_default.png)
   * clickhouse_default
     * ![ch](/docs/clickhouse_default.png)
   * postgres_default
     * ![ch](/docs/postgres_default.png)