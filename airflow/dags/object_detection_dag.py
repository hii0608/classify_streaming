from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import pandas as pd
from sqlalchemy import create_engine
import cv2
import your_yolo_module  # YOLOv9 관련 모듈

# PostgreSQL 연결 설정
DB_URI = "postgresql+psycopg2://airflow:airflow@postgres:5432/detection_results"
engine = create_engine(DB_URI)

def process_video(video_path, **context):
    # YOLO 모델 로드
    model = your_yolo_module.load_model()
    
    # 비디오 처리
    detections = []
    video = cv2.VideoCapture(video_path)
    frame_count = 0
    
    while video.isOpened():
        ret, frame = video.read()
        if not ret:
            break
            
        # YOLO로 객체 검출
        results = model.detect(frame)
        
        # 결과를 리스트에 추가
        for detection in results:
            detections.append({
                'timestamp': datetime.now(),
                'source_type': 'video',
                'source_id': video_path,
                'frame_number': frame_count,
                'object_class': detection.class_name,
                'confidence': detection.confidence,
                'bbox_x': detection.bbox[0],
                'bbox_y': detection.bbox[1],
                'bbox_width': detection.bbox[2],
                'bbox_height': detection.bbox[3],
                'track_id': detection.track_id
            })
        
        frame_count += 1
    
    # 결과를 DataFrame으로 변환하여 PostgreSQL에 저장
    df = pd.DataFrame(detections)
    df.to_sql('object_detections', engine, if_exists='append', index=False)
    
    # 요약 통계 생성
    summary = df.groupby(['source_id', 'object_class']).size().reset_index(name='detection_count')
    summary['timestamp'] = datetime.now()
    summary['source_type'] = 'video'
    summary['time_window'] = '1hour'
    
    summary.to_sql('detection_summary', engine, if_exists='append', index=False)

# DAG 정의
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'object_detection_pipeline',
    default_args=default_args,
    description='Object detection pipeline using YOLOv9 and DeepSORT',
    schedule_interval=timedelta(hours=1),
)

process_video_task = PythonOperator(
    task_id='process_video',
    python_callable=process_video,
    op_kwargs={'video_path': '/path/to/video'},
    dag=dag,
) 