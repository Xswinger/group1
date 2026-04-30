#!/usr/bin/env python3

import csv
import random
import time
import os
from datetime import datetime, timedelta

TOTAL_ROWS = 5_000_000
OUTPUT_FILE = "sql/test_data.csv"

HOSTS = [f'host-{i:03d}' for i in range(1, 51)]
METRICS = ['cpu_usage', 'memory_usage', 'disk_io', 'network_rx', 'network_tx',
           'disk_usage', 'load_average', 'iops_read', 'iops_write', 'temperature']
END_TIME = datetime.now()
START_TIME = END_TIME - timedelta(days=30)


def generate_value(metric_name):
    if metric_name == 'cpu_usage':
        return round(random.uniform(0, 100), 2)
    elif metric_name == 'memory_usage':
        return round(random.uniform(1024, 65536), 2)
    elif metric_name == 'disk_io':
        return round(random.uniform(0, 500), 2)
    elif metric_name == 'network_rx' or metric_name == 'network_tx':
        return round(random.uniform(0, 10000), 2)
    elif metric_name == 'disk_usage':
        return round(random.uniform(0, 100), 2)
    elif metric_name == 'load_average':
        return round(random.uniform(0, 32), 2)
    elif metric_name == 'iops_read' or metric_name == 'iops_write':
        return round(random.uniform(0, 10000), 0)
    elif metric_name == 'temperature':
        return round(random.uniform(20, 90), 1)
    else:
        return round(random.uniform(0, 1000), 2)


def generate_csv_file():
    print(f"Generating CSV with {TOTAL_ROWS:,} rows...")
    
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    with open(OUTPUT_FILE, 'w', newline='') as f:
        writer = csv.writer(f)
        
        for i in range(TOTAL_ROWS):
            random_seconds = random.randint(0, int((END_TIME - START_TIME).total_seconds()))
            timestamp = START_TIME + timedelta(seconds=random_seconds)
            
            host = random.choice(HOSTS)
            metric = random.choice(METRICS)
            value = generate_value(metric)
            
            writer.writerow([
                timestamp.strftime('%Y-%m-%d %H:%M:%S'),
                host,
                metric,
                value
            ])
    
    print(f"\nCSV generated: {OUTPUT_FILE}")


if __name__ == "__main__":
    print("=" * 60)
    print("ClickHouse Test Data CSV Generator")
    print("=" * 60)
    generate_csv_file()
    print("=" * 60)