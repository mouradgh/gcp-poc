# gcp-poc
A Terraform managed GCP project

## Overview

This is a template project for an end-to-end data engineering pipeline.
The technichal stack used is :

- Terraform for IaC
- Cloud Functions (Python) for scripting
- Cloud Composer (Apache Airflow) for orchestration
- AlloyDB for the Postgres database

## HCP Terrafom

This project's Terraform files are hosted on HCP Terraform, allowing automatic deploys every time new code is pushed to GitHub.

The GCP credentials and the other sensitive variables are stored as Terraform variables in the HCP TF UI.

## File structure

The .terraform folder contains the TF code :
- main.tf for the provider declaration (GCP) and the HCP Terraform connection
- gcs.tf contains the Google Cloud Storage bucket declarations
- gcf.tf contains the Cloud Run Functions
- gcc.tf contains the Cloud Composer instance
- variables.tf contains the variables

The functions folder contains the Cloud Functions code :
- xml-to-json-converter to automatically convert XML files to JSON


## Cloud Run Function

Every time an XML file is dropped at the ```gigawatt-raw-data``` GCS bucket, it is automatically converted to a JSON file and dropped at the ```gigawatt-transformed-data``` GCS bucket.

This transformation is done using the Cloud Run Function ```xml-to-json-converter```

## Airflow DAGs

The `dags/` directory contains all Airflow DAGs that will be automatically deployed to Cloud Composer. 

To add a new DAG you can create a new Python file in the `dags/` directory
The DAG will be automatically uploaded to your Cloud Composer environment.