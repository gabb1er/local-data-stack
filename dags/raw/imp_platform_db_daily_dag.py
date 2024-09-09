from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow_clickhouse_plugin.hooks.clickhouse import ClickHouseHook

DAG_ID = "imp_platform_db_daily_dag"

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
}

def transfer_data(table, execution_date):
    # Initialize PostgreSQL hook
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    pg_conn = pg_hook.get_conn()
    pg_cursor = pg_conn.cursor()

    # Query data from PostgreSQL
    pg_cursor.execute(f'SELECT * FROM {table}')
    rows = pg_cursor.fetchall()
    column_names = [desc[0].lower() for desc in pg_cursor.description]
    column_names.append('load_date')

    # Initialize ClickHouse hook
    ch_hook = ClickHouseHook(clickhouse_conn_id='clickhouse_default')

    ch_table = f"raw_platform_db_{table}"

    # Insert data into ClickHouse
    ch_hook.execute(f"ALTER TABLE {ch_table} DROP PARTITION '{execution_date}';")
    insert_query = f'INSERT INTO {ch_table} ({", ".join(column_names)}) VALUES'

    value_str = ', '.join('(' + ', '.join('\''+str(x)+'\'' for x in row) + f', \'{execution_date}\')' for row in rows)

    # Execute insert
    ch_hook.execute(sql=f"{insert_query} {value_str}")

    # Clean up
    pg_cursor.close()
    pg_conn.close()


with DAG(
        dag_id=DAG_ID,
        default_args=default_args,
        description='Platform DB import DAG',
        schedule_interval='@daily',
        start_date=datetime(2024, 7, 1),
        catchup=True,
) as dag:

    tables = [
        'catalogitems', 'catalogs', 'companies', 'endcustomers',
        'orderitems', 'orders', 'products', 'suppliers'
    ]

    list(map(lambda table: PythonOperator(
        task_id=f'load_{table}',
        python_callable=transfer_data,
        op_kwargs={
            'execution_date': '{{ ds }}',
            'table': table
        },
        provide_context=True,
    ), tables))

