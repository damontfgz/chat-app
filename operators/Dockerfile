FROM python:3.10-slim
RUN pip install kopf kubernetes requests
COPY main.py /app/main.py
WORKDIR /app
CMD ["kopf", "run", "--standalone", "main.py"]