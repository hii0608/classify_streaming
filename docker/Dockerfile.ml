FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    libre2-dev \    # google-re2 관련 문제 해결을 위한 라이브러리
    && rm -rf /var/lib/apt/lists/*

# Python 패키지 설치
COPY requirements.txt .

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

# Airflow 설치
ENV AIRFLOW_HOME=/opt/airflow
RUN pip3 install apache-airflow==2.5.0

# MLflow 설치
RUN pip3 install mlflow==2.1.0

# 작업 디렉토리 설정
WORKDIR /workspace

# 시작 스크립트 복사 및 실행 권한 부여
COPY start-services.sh /start-services.sh
RUN chmod +x /start-services.sh

# 기본 실행 명령
CMD ["/start-services.sh"]
