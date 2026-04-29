# Групповая работа 1

| Участник | Зона ответственности |
|----------|----------------------|
|    | ClickHouse-кластер, DDL, данные |
|   | Nginx, балансировка, health checks |
|   | Prometheus + Grafana, дашборды |
| Игорь Аллаяров | Keeper, fault injection, Makefile |

## Часть №1

1) Кластер разворачивается с помощью docker-compose в Docker контейнерах (конфигурация описана в docker-compose.yaml)
2) В конфигурации контейнеров используется шаблон для настройки clickhouse узлов (clickhouse-common)
3) Для удобства управления создан Makefile с целями:
* make up / make down - запуск и оставновка кластера
* make status - отображение состояния сервисов
* make test - запуск проверок

## Часть №2

1) В рамках кластера разворачиваются 2 шарда по 2 реплики в каждом (clickhouse1 и clickhouse2 в 1 шарде, clickhouse3 и clickhouse4 во 2 шарде)
2) Таблицы создаются с запуском 1 реплики 1 шарда (clickhouse1) и синхронизируются с остальными узлами
3) Данные генерируются файлом scripts/generate_data.py. Вставка происходит во время запуска кластера.
4) Демонстрация:
* Данные распределены по шардам:

Запрос к 1 реплике:
```shell
docker exec clickhouse1 clickhouse-client --query "
    SELECT 
        count() as rows,
        sum(value) as total_value,
        avg(value) as avg_value,
        min(timestamp) as min_time,
        max(timestamp) as max_time
    FROM metrics.metrics_local
    FORMAT Pretty
"
```

Ответ:
```sql
┏━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃    rows ┃        total_value ┃         avg_value ┃            min_time ┃            max_time ┃
┡━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│ 2500000 │ 13415002960.529999 │ 5366.001184211999 │ 2026-03-27 11:53:49 │ 2026-04-26 11:53:49 │
└─────────┴────────────────────┴───────────────────┴─────────────────────┴─────────────────────┘
```

Запрос к 3 реплике:
```shell
docker exec clickhouse3 clickhouse-client --query "
    SELECT 
        count() as rows,
        sum(value) as total_value,
        avg(value) as avg_value,
        min(timestamp) as min_time,
        max(timestamp) as max_time
    FROM metrics.metrics_local
    FORMAT Pretty
"
```

Ответ:
```sql
┏━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃    rows ┃   total_value ┃     avg_value ┃            min_time ┃            max_time ┃
┡━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│ 2500000 │ 13418847385.6 │ 5367.53895424 │ 2026-03-27 11:53:50 │ 2026-04-26 11:53:49 │
└─────────┴───────────────┴───────────────┴─────────────────────┴─────────────────────┘
```
* Реплики синхронизированы в рамках 1 шарда:

Запрос к 1 реплике:
```shell
docker exec clickhouse1 clickhouse-client --query "
    SELECT 
        count() as rows,
        sum(value) as total_value,
        avg(value) as avg_value,
        min(timestamp) as min_time,
        max(timestamp) as max_time
    FROM metrics.metrics_distributed
    FORMAT Pretty
"
```

Ответ:
```sql
┏━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃    rows ┃        total_value ┃         avg_value ┃            min_time ┃            max_time ┃
┡━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│ 5000000 │ 26833850346.129997 │ 5366.770069226001 │ 2026-03-27 11:53:49 │ 2026-04-26 11:53:49 │
└─────────┴────────────────────┴───────────────────┴─────────────────────┴─────────────────────┘
```

Запрос ко 2 реплике:
```shell
docker exec clickhouse2 clickhouse-client --query "
    SELECT 
        count() as rows,
        sum(value) as total_value,
        avg(value) as avg_value,
        min(timestamp) as min_time,
        max(timestamp) as max_time
    FROM metrics.metrics_distributed
    FORMAT Pretty
"
```

Ответ:
```sql
┏━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃    rows ┃        total_value ┃          avg_value ┃            min_time ┃            max_time ┃
┡━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│ 5000000 │ 26833850346.129997 │ 5366.7700692260005 │ 2026-03-27 11:53:49 │ 2026-04-26 11:53:49 │
└─────────┴────────────────────┴────────────────────┴─────────────────────┴─────────────────────┘
```

* Запросы через metrics_distributed:

Запрос к 3 реплике:
```shell
docker exec clickhouse3 clickhouse-client --query "
    SELECT 
        count() as rows,
        sum(value) as total_value,
        avg(value) as avg_value,
        min(timestamp) as min_time,
        max(timestamp) as max_time
    FROM metrics.metrics_distributed
    FORMAT Pretty
"
```

Ответ:
```sql
┏━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃    rows ┃        total_value ┃      avg_value ┃            min_time ┃            max_time ┃
┡━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│ 5000000 │ 26833850346.129997 │ 5366.770069226 │ 2026-03-27 11:53:49 │ 2026-04-26 11:53:49 │
└─────────┴────────────────────┴────────────────┴─────────────────────┴─────────────────────┘
```

## Часть №3

1) Проксирование запросов происходит через HTTP-интерфейс по портам 8123
2) От каждого шарда 1 реплика используется как основная и 1 как резервная.  
3) Исключение упавшего узла происходит по прошествию 3 неудачных попыток подключения с последующим его исключением из работы на 30 секунд
4) Access-логи сохраняются по пути /var/log/nginx/access.log и имеют следующий формат:
```
log_format json_combined escape=json '{'
    '"time_local":"$time_local",'
    '"remote_addr":"$remote_addr",'
    '"remote_user":"$remote_user",'
    '"request":"$request",'
    '"status":$status,'
    '"body_bytes_sent":$body_bytes_sent,'
    '"request_time":$request_time,'
    '"http_referrer":"$http_referer",'
    '"http_user_agent":"$http_user_agent",'
    '"upstream_addr":"$upstream_addr",'
    '"upstream_status":$upstream_status,'
    '"upstream_response_time":"$upstream_response_time"'
'}';
```

Пример лога:
```
{
    "time_local":"26/Apr/2024:12:30:45 +0000",
    "remote_addr":"192.168.1.100",
    "remote_user":"-",
    "request":"GET /?query=SELECT%201 HTTP/1.1",
    "status":200,
    "body_bytes_sent":15,
    "request_time":0.023,
    "http_referrer":"-",
    "http_user_agent":"curl/7.68.0",
    "upstream_addr":"172.18.0.5:8123",
    "upstream_status":200,
    "upstream_response_time":"0.020"
}
```
5) Проверка балансировщика:
Запрос:
```
curl "http://localhost:8080/?query=SELECT%20count()%20FROM%20metrics.metrics_distributed"
```

Ответ:
```
5000000
```

Запрос после остановки 1 реплики:
```
curl "http://localhost:8080/?query=SELECT%20count()%20FROM%20metrics.metrics_distributed"
```

Ответ:
```
5000000
```

## Часть №4

1) Prometheus собирает метрики каждой реплики через эндпоинт ```/metrics```. Пример отображения метрики для 1 реплики:
```shell
curl -s http://localhost:9363/metrics | grep -i query
```

2) Дашборд отображает 4 панели исходя из задания, но панели числа строк по таблицам и статуса реплики отображаются некорректно (судя по всему по причине сложности интерпретации grafana данных напрямую из clickhouse, в отличие от prometheus)
3) Конфигурация дашборда лежит по пути /monitoring/dashboards
4) Дашборд автоматически подтягивается вместе с запуском кластера через конфигурацию контейнера в docker-compose.yml

## Часть №5

1) Доступность данных при потере реплики продемонстрирована в рамках Части 3 пункта 5
2) Проверка работоспособности при потере шарда

Запрос к 3 реплике:
```shell
docker exec clickhouse3 clickhouse-client --query "
    SELECT 
        count() as rows,
        sum(value) as total_value,
        avg(value) as avg_value,
        min(timestamp) as min_time,
        max(timestamp) as max_time
    FROM metrics.metrics_distributed
    FORMAT Pretty
"
```

Ответ:
```
Error response from daemon: container 81da67181a7a54288f8c9fd856f9eba2d726838350b20b14ea9bcc4afa024096 is not running
```

Запрос к кластеру:
```
curl "http://localhost:8080/?query=SELECT%20count()%20FROM%20metrics.metrics_distributed"
```

Ответ:
```shell
Code: 279. DB::NetException: All connection tries failed. Log: 

Code: 32. DB::Exception: Attempt to read after eof. (ATTEMPT_TO_READ_AFTER_EOF) (version 23.8.16.16 (official build))
Code: 32. DB::Exception: Attempt to read after eof. (ATTEMPT_TO_READ_AFTER_EOF) (version 23.8.16.16 (official build))
Timeout exceeded while connecting to socket (clickhouse4:9000, connection timeout 1000 ms)
Timeout exceeded while connecting to socket (clickhouse3:9000, connection timeout 1000 ms)
Timeout exceeded while connecting to socket (clickhouse4:9000, connection timeout 1000 ms)
Timeout exceeded while connecting to socket (clickhouse3:9000, connection timeout 1000 ms)

: While executing Remote. (ALL_CONNECTION_TRIES_FAILED) (version 23.8.16.16 (official build))
```

3) Проверка работоспособности при потере 1 keeper

Вставка тестовых данных:
```shell
make load-data
```

Результат:
```shell
Waiting for ClickHouse...
Checking tables...
Loading data...
Done!
=== Checking Data Distribution ===
Data distribution check completed. See checks/data_distribution.txt
```

Запрос к кластеру:
```
curl "http://localhost:8080/?query=SELECT%20count()%20FROM%20metrics.metrics_distributed"
```

Ответ:
```shell
5000000
```

4) Проверка работоспособности при потере кворума keeper

Запрос к кластеру:
```
curl "http://localhost:8080/?query=SELECT%20count()%20FROM%20metrics.metrics_distributed"
```

Ответ:
```shell
0
```

Вставка тестовых данных:
```shell
make load-data
```

Результат:
```shell
Waiting for ClickHouse...
Checking tables...
Loading data...
```

Пояснение - скрипт вставки замирает на попытке вставить данные к таблицу, при этом в логах 1 реплики появляются ошибки о невозможности найти узел кластера keeper:
```shell
2026.04.26 18:37:59.536088 [ 370 ] {} <Error> metrics.metrics_local (ReplicatedMergeTreeRestartingThread): Failed to establish a new ZK connection. Will try again: Code: 999. Coordination::Exception: Cannot use any of provided ZooKeeper nodes.
```