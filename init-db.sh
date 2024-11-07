#!/bin/bash


set -e
set -u

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    # Airflow 메타데이터용 데이터베이스
    CREATE DATABASE airflow;
    GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
EOSQL

# MLflow 데이터베이스 생성
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE mlflow;
    GRANT ALL PRIVILEGES ON DATABASE mlflow TO airflow;

    CREATE DATABASE detection_results;
    GRANT ALL PRIVILEGES ON DATABASE detection_results TO airflow;
EOSQL

# detection_results 데이터베이스에 테이블 생성
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d detection_results <<-EOSQL
    CREATE TABLE IF NOT EXISTS object_detections (
        id SERIAL PRIMARY KEY,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        source_type VARCHAR(50),  -- video or camera
        source_id VARCHAR(255),   -- video file name or camera id
        frame_number INTEGER,
        object_class VARCHAR(100),
        confidence FLOAT,
        bbox_x FLOAT,
        bbox_y FLOAT,
        bbox_width FLOAT,
        bbox_height FLOAT,
        track_id INTEGER          -- from DeepSORT
    );

    CREATE TABLE IF NOT EXISTS detection_summary (
        id SERIAL PRIMARY KEY,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        source_type VARCHAR(50),
        source_id VARCHAR(255),
        time_window VARCHAR(50),  -- e.g., '5min', '1hour'
        object_class VARCHAR(100),
        detection_count INTEGER
    );
EOSQL