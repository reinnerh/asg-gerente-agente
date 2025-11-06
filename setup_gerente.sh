#!/bin/bash

# Atualiza pacotes e instala dependências
apt update -y
apt install -y python3-pip
pip3 install boto3 --break-system-packages

# Cria o script de monitoramento
cat <<EOF > /opt/asg_monitor.py
import boto3, time, logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

sqs = boto3.client('sqs', region_name='sa-east-1')
asg = boto3.client('autoscaling', region_name='sa-east-1')

QUEUE_URL = '${QUEUE_URL}'
ASG_NAME = 'Plataforma Jornada'

logging.info("ASG Monitor iniciado.")

while True:
    msgs = sqs.receive_message(QueueUrl=QUEUE_URL, MaxNumberOfMessages=10, WaitTimeSeconds=10)
    if 'Messages' in msgs:
        logging.info(f"Mensagens recebidas: {len(msgs['Messages'])}")
        current = asg.describe_auto_scaling_groups(AutoScalingGroupNames=[ASG_NAME])['AutoScalingGroups'][0]['DesiredCapacity']
        logging.info(f"Escalando de {current} para {current + 1}")
        asg.update_auto_scaling_group(AutoScalingGroupName=ASG_NAME, DesiredCapacity=current + 1)

        for msg in msgs['Messages']:
            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])
    else:
        logging.info("Nenhuma mensagem recebida.")
    time.sleep(5)
EOF

chmod +x /opt/asg_monitor.py

# Cria o serviço systemd
cat <<EOF > /etc/systemd/system/asg_gerente.service
[Unit]
Description=ASG Gerente Monitor de CPU
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/asg_monitor.py
WorkingDirectory=/opt
StandardOutput=append:/var/log/asg_monitor.log
StandardError=append:/var/log/asg_monitor.log
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Ativa e inicia o serviço
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable asg_gerente.service
systemctl start asg_gerente.service
