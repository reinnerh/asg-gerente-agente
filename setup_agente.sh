#!/bin/bash

# Atualiza pacotes e instala dependências
apt update -y
apt install -y python3-pip
pip3 install psutil boto3 --break-system-packages

# Cria o script de monitoramento
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

chmod +x /opt/cpu_check.py

# Cria o serviço systemd
cat <<EOF > /etc/systemd/system/asg_agente.service
[Unit]
Description=ASG Agente CPU Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/cpu_check.py
WorkingDirectory=/opt
StandardOutput=append:/var/log/cpu_check.log
StandardError=append:/var/log/cpu_check.log
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Ativa e inicia o serviço
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable asg_agente.service
systemctl start asg_agente.service
