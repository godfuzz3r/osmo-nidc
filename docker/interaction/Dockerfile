FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y netcat-traditional

ENV DOCKER_ENV=true

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

ENTRYPOINT ["bash", "/app/entrypoint.sh"]