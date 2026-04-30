SELECT sleep(3);

CREATE DATABASE IF NOT EXISTS metrics ON CLUSTER production;

CREATE TABLE IF NOT EXISTS metrics.metrics_local ON CLUSTER production
(
    timestamp DateTime,
    host String,
    metric_name String,
    value Float64
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/metrics_local', '{replica}')
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (host, metric_name, timestamp)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS metrics.metrics_distributed ON CLUSTER production
(
    timestamp DateTime,
    host String,
    metric_name String,
    value Float64
)
ENGINE = Distributed('production', 'metrics', 'metrics_local', rand());