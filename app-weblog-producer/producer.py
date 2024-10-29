import logging
import os
import random
import time
from datetime import datetime

import re
import json

from kafka import KafkaProducer
from kafka.errors import KafkaError

logger = logging.getLogger(__name__)

KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
KAFKA_TOPIC = os.getenv('KAFKA_TOPIC', 'my_topic')

producer = KafkaProducer(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS)

# List of possible elements for generating log entries
users = ['DN123456', 'DN654321', 'DN789012', 'DN345678', 'DN987654', 'DN543210', '-']
methods = ['GET', 'POST', 'DELETE', 'PUT']
resources = ['/index.html', '/about', '/contact', '/products', '/services']
statuses = [200, 301, 404, 500]
referers = ['http://platform.com', 'http://sales.com', '-', 'http://vendor.com']
user_agents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:45.0) Gecko/20100101 Firefox/45.0',
    'Mozilla/5.0 (Linux; Android 8.0.0; SM-T350 Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15A5370a Safari/604.1',
    'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.152 Mobile Safari/537.36',
    'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15A5370a Safari/604.1'
]

ips = ['185.216.35.28', '104.16.132.229', '142.250.190.78', '216.58.206.46', '172.217.168.163', '172.217.160.78']

def generate_log_entry():
    """Generate a single log entry in the Combined Log Format."""
    # ip = f'{random.randint(100, 200)}.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}'
    ip = random.choice(ips)
    user_identifier = '-'
    user_id = random.choice(users)
    time_stamp = datetime.now().strftime('%d/%b/%Y:%H:%M:%S %z')
    method = random.choice(methods)
    resource = random.choice(resources)
    protocol = 'HTTP/1.1'
    status_code = random.choice(statuses)
    size = random.randint(100, 5000)
    referer = random.choice(referers)
    user_agent = random.choice(user_agents)

    log_entry = f'{ip} {user_identifier} {user_id} [{time_stamp}] "{method} {resource} {protocol}" {status_code} {size} "{referer}" "{user_agent}"'
    return log_entry

log_pattern = re.compile(r'(?P<ip>\S+) (?P<identity>[^"]+) (?P<username>[^"]+) \[(?P<timestamp>[^\]]+)\] "(?P<request>[^"]+)" (?P<status>\d{3}) (?P<size>\d+) "(?P<referrer>[^"]+)" "(?P<user_agent>[^"]+)"')

def parse_log_entry(log_line):
    match = log_pattern.match(log_line)
    if match:
        return {
            "ip": match.group("ip"),
            "identity": match.group("identity"),
            "username": match.group("username"),
            "timestamp": match.group("timestamp"),
            "request": match.group("request"),
            "status": match.group("status"),
            "size": match.group("size"),
            "referrer": match.group("referrer"),
            "user_agent": match.group("user_agent"),
        }
    else:
        return None

def send_message(producer: KafkaProducer, topic: str, message: str) -> None:
    try:
        future = producer.send(topic, message.encode('utf-8'))
        result = future.get(timeout=10)
        logger.info(f"Sent: {message}")
    except KafkaError as e:
        logger.info(f"Failed to send message: {e}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, handlers=[logging.FileHandler("producer.log"), logging.StreamHandler()])
    logger.info("Starting Kafka producer...")
    logger.info(f"Bootstrap server: {KAFKA_BOOTSTRAP_SERVERS}, topic: {KAFKA_TOPIC}")

    while True:
        message = generate_log_entry()
        parsed_log = parse_log_entry(message)
        if parsed_log:
            json_output = json.dumps(parsed_log, indent=4)
            send_message(producer, KAFKA_TOPIC, json_output)
        else:
            logger.error("Failed to parse log line.")

        time.sleep(1)
