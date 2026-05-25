FROM pytorch/pytorch:2.0.0-cuda11.7-cudnn8-runtime

# Downloads to user config dir
ADD https://ultralytics.com/assets/Arial.ttf https://ultralytics.com/assets/Arial.Unicode.ttf /root/.config/Ultralytics/

# Install linux packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    TZ=Etc/UTC apt-get install -y tzdata && \
    apt-get install --no-install-recommends -y \
        gcc git zip curl htop libgl1-mesa-glx libglib2.0-0 libpython3-dev gnupg g++ && \
    apt-get upgrade --no-install-recommends -y openssl tar && \
    rm -rf /var/lib/apt/lists/*

# Pin to a version with a working MLflow callback
RUN pip install --no-cache-dir \
    ultralytics==8.2.103 \
    azureml-mlflow==1.57.0 \
    mlflow==2.15.1

# Disable Ultralytics' MLflow integration at the settings level (belt and braces)
# RUN yolo settings mlflow=False || true