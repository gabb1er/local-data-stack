# Local Data Stack

## Overview

This collection of docker-compose files enables you to launch various services on your
local machine with ease.
I utilize it to test and implement innovative ideas and integrations effectively.

## Components

| Name                | UI URL                | Version                      | Compose path                           |
|---------------------|-----------------------|------------------------------|----------------------------------------|
| Postgres            |                       | 15-alpine                    | docker-compose.yml                     |
| Clickhouse          |                       | 24.3-alpine                  | docker-compose.yml                     |
| MinIO (S3)          | http://localhost:9001 | RELEASE.2024-01-29T03-56-32Z | docker-compose.yml                     |
| Kafka               |                       | 7.2.1                        | storage-kafka/docker-compose.yml       |
| MLflow              | http://localhost:5000 | v2.10.2                      | service-mlflow/docker-compose.yml      |
| Airflow             | http://localhost:8081 | 2.9.3                        | service-airflow/docker-compose.yml     |
| Redis               |                       | 7.2-bookworm                 | service-airflow/docker-compose.yml     |
| JupyterLab          | http://localhost:8000 | 4.0.7 (latest of dockerhub)  | service-jupyterlab/docker-compose.yml  |
| Trino               | http://localhost:8080 | 463                          | service-trino/docker-compose.yml       |
| WebLog Producer App |                       |                              | app-weblog-producer/docker-compose.yml |
| TinyLLama API       |                       |                              | app-llm/docker-compose.yml             |

## Architecture

All services share

![Architecrtural](/docs/architecture.png)

## Installation

The project is origanized inside the `docker-compose.yml`, but it's highly advised to follow these steps:

0. Copy .env to airflow and mlflow dirs
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