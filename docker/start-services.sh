#!/bin/bash

# Airflow 웹서버 시작
airflow webserver -p 8080 &

# Airflow 스케줄러 시작
airflow scheduler &

# MLflow 서버 시작
mlflow server \
    --backend-store-uri postgresql+psycopg2://airflow:airflow@postgres:5432/mlflow \
    --default-artifact-root /mlflow \
    --host 0.0.0.0 \
    --port 5000 &

# 컨테이너를 계속 실행 상태로 유지
tail -f /dev/null