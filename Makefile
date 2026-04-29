.PHONY: up down status check-data generate-data load-data

up:
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 30
	@echo "Cluster is ready!"

down:
	docker-compose down -v

status:
	@echo "=== Services Status ==="
	@docker-compose ps
	@echo "\n=== ClickHouse Cluster Status ==="
	@docker exec clickhouse1 clickhouse-client --query "SELECT * FROM system.clusters WHERE cluster = 'production' FORMAT Pretty"
	@echo "\n=== Replication Status ==="
	@docker exec clickhouse1 clickhouse-client --query "SELECT database, table, is_leader, is_readonly, total_replicas, active_replicas FROM system.replicas FORMAT Pretty"

check-data:
	@echo "=== Checking Data Distribution ==="
	@docker exec clickhouse1 clickhouse-client --query "SELECT shardNum() as shard, count() as rows, sum(value) as total_value FROM metrics.metrics_distributed GROUP BY shard ORDER BY shard FORMAT Pretty" > checks/data_distribution.txt
	@echo "Data distribution check completed. See checks/data_distribution.txt"

generate-data:
	python3 /scripts/generate_data.py

load-data:
	@if [ ! -f sql/test_data.csv ]; then \
		echo "Run 'make generate-data' first."; \
		exit 1; \
	fi
	@echo "Waiting for ClickHouse..."
	@for i in $$(seq 1 30); do \
		if docker exec clickhouse1 clickhouse-client --query "SELECT 1" &>/dev/null; then \
			break; \
		fi; \
		sleep 2; \
	done
	@echo "Checking tables..."
	@for i in $$(seq 1 30); do \
		if docker exec clickhouse1 clickhouse-client --query "EXISTS TABLE metrics.metrics_distributed" 2>/dev/null | grep -q "1"; then \
			break; \
		fi; \
		echo "Waiting for tables... $$i"; \
		sleep 3; \
	done
	@echo "Loading data..."
	@cat sql/test_data.csv | docker exec -i clickhouse1 clickhouse-client \
		--query "INSERT INTO metrics.metrics_distributed FORMAT CSV"
	@echo "Done!"
	@make check-data
