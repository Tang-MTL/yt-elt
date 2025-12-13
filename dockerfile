ARG AIRFlOW_VERSION=2.12.3
ARG PYTHOON_VERSION=3.10

from apache/airflow:${AIRFlOW_VERSION}-python${PYTHOON_VERSION}-slim-buster

ENV AIRFLOW_HOME=/opt/airflow

COPY requirements.txt /

RUN pip install --no-cache-dir "apache-airflow==${AIRFlOW_VERSION}" -r /requirements.txt
