import io
from datetime import datetime

import pandas as pd
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow_clickhouse_plugin.hooks.clickhouse import ClickHouseHook


DAG_ID = "exp_reports_daily_dag"

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
}

def read_from_ch(table):
    ch_hook = ClickHouseHook(clickhouse_conn_id='clickhouse_default')

    # SQL query to fetch data
    sql_query = f"SELECT * FROM dwh.{table};"

    # Fetch data
    results = ch_hook.execute(sql_query)
    df = pd.DataFrame(results)
    return df


def upload_to_s3(df, key, bucket_name, execution_date):
    # Initialize S3 hook
    s3_hook = S3Hook(aws_conn_id='minio_default')

    # Convert DataFrame to CSV
    csv_buffer = io.BytesIO()
    df.to_excel(csv_buffer, index=False)

    # Upload CSV to S3
    s3_hook.load_bytes(
        csv_buffer.getvalue(),
        key=f'load_date={execution_date}/{key}.xlsx',
        bucket_name=bucket_name,
        replace=True
    )


def ch_to_s3(execution_date, table):
    df = read_from_ch(table)
    upload_to_s3(df, table, "reports", execution_date)


with DAG(
        dag_id=DAG_ID,
        default_args=default_args,
        description='Reports export dag',
        schedule_interval='@daily',
        start_date=datetime(2024, 7, 1),
        catchup=True,
) as dag:

    tables = [
        'report_top_product_by_country',
        'report_most_popular_device',
        'report_monthly_sales'
    ]

    list(map(lambda table: PythonOperator(
        task_id=f'export_{table}',
        python_callable=ch_to_s3,
        op_kwargs={
            'execution_date': '{{ ds }}',
            'table': table
        },
        provide_context=True,
    ), tables))

