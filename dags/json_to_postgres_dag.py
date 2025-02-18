from airflow import DAG
from airflow.providers.google.cloud.operators.gcs import GCSListObjectsOperator
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import json

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def load_json_to_postgres(**context):
    # Get the list of files from XCom
    task_instance = context['task_instance']
    files = task_instance.xcom_pull(task_ids='list_json_files')
    
    if not files:
        print("No files to process")
        return
    
    # Initialize GCS and Postgres hooks
    gcs_hook = GCSHook()
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    for file_path in files:
        # Download and parse JSON content
        file_content = gcs_hook.download(
            bucket_name='gigawatt-processed-data',
            object_name=file_path
        ).decode('utf-8')
        
        json_data = json.loads(file_content)
        
        # Assuming each JSON file contains an array of records
        if isinstance(json_data, list):
            records = json_data
        else:
            records = [json_data]  # Single record
        
        for record in records:
            # Dynamically create INSERT statement based on JSON structure
            columns = list(record.keys())
            values = [record[col] for col in columns]
            placeholders = '%s' * len(columns)
            
            insert_query = f"""
                INSERT INTO processed_data ({', '.join(columns)})
                VALUES ({', '.join(['%s' for _ in columns])})
                ON CONFLICT DO NOTHING;
            """
            
            # Execute insert
            pg_hook.run(
                insert_query,
                parameters=values
            )
            
        print(f"Processed file: {file_path}")

# Create the DAG
dag = DAG(
    'json_to_postgres_loader',
    default_args=default_args,
    description='Load JSON files from GCS to Postgres',
    schedule_interval='@daily',
    catchup=False
)

# Task to list JSON files in the bucket
list_files = GCSListObjectsOperator(
    task_id='list_json_files',
    bucket='gigawatt-processed-data',
    prefix='',  # You can add a prefix if files are in a specific folder
    delimiter='.json',  # Only list JSON files
    dag=dag
)

# Task to process files and load to Postgres
load_to_postgres = PythonOperator(
    task_id='load_to_postgres',
    python_callable=load_json_to_postgres,
    provide_context=True,
    dag=dag
)

# Set task dependencies
list_files >> load_to_postgres 