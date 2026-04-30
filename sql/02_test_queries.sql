SELECT * FROM system.clusters WHERE cluster = 'production' FORMAT Vertical;

SELECT 
    database,
    table,
    is_leader,
    is_readonly,
    is_session_expired,
    future_parts,
    parts_to_check,
    zookeeper_path,
    replica_path,
    columns_version,
    queue_size,
    inserts_in_queue,
    merges_in_queue,
    replication_lag
FROM system.replicas
FORMAT Vertical;

SELECT 
    shardNum() as shard,
    count() as rows_count,
    sum(value) as total_value,
    avg(value) as avg_value
FROM metrics.metrics_distributed
GROUP BY shard
ORDER BY shard;