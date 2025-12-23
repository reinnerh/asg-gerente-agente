#!/bin/bash


apt update -y
apt install -y python3-pip
pip3 install boto3 --break-system-packages


mkdir -p /var/log


cat <<EOF > /opt/asg_monitor.py
import boto3, time, logging

# Configura o log
logging.basicConfig(
    filename='/var/log/asg_monitor.log',
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

sqs = boto3.client('sqs', region_name='sa-east-1')
asg = boto3.client('autoscaling', region_name='sa-east-1')

QUEUE_URL = '${QUEUE_URL}'
ASG_NAME = 'asg-name'

logging.info("ASG Monitor iniciado.")

while True:
    try:
        msgs = sqs.receive_message(QueueUrl=QUEUE_URL, MaxNumberOfMessages=10, WaitTimeSeconds=10)
        if 'Messages' in msgs:
            logging.info(f"Mensagens recebidas: {len(msgs['Messages'])}")
            current = asg.describe_auto_scaling_groups(AutoScalingGroupNames=[ASG_NAME])['AutoScalingGroups'][0]['DesiredCapacity']
            logging.info(f"Escalando de {current} para {current + 1}")
            asg.update_auto_scaling_group(AutoScalingGroupName=ASG_NAME, DesiredCapacity=current + 1)

            for msg in msgs['Messages']:
                sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])
                logging.info(f"Mensagem processada e deletada: {msg['MessageId']}")
        else:
            logging.info("Nenhuma mensagem recebida.")

    except Exception as e:
        logging.error(f"Erro ao processar mensagens: {str(e)}")

    time.sleep(5)
EOF

# Roda o script em segundo plano e envia log para /var/log/asg_monitor.log
nohup python3 /opt/asg_monitor.py > /var/log/asg_monitor.log 2>&1 &
