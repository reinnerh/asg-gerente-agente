#!/bin/bash
apt update -y
apt install -y python3-pip
pip3 install psutil --break-system-packages

cat <<EOF > /opt/cpu_check.py
import boto3, psutil, time, socket
sqs = boto3.client('sqs', region_name='sa-east-1')
QUEUE_URL = '${QUEUE_URL}'
INSTANCE_ID = socket.gethostname()

while True:
    cpu = psutil.cpu_percent(interval=1)
    if cpu > 85:
        sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=f"{INSTANCE_ID}:{cpu}")
    time.sleep(10)
EOF

nohup python3 /opt/cpu_check.py &