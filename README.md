# Beverage Filling Line - Data Infrastructure

A complete data infrastructure stack for processing and enriching beverage filling line data using MQTT, Redis, and Kafka (Redpanda).

## Architecture Overview

This setup creates a data pipeline that:
1. **Receives** real-time data from the OPC UA server via MQTT
2. **Stores** contextual data (production orders, machine info) in Redis
3. **Enriches** streaming metrics with production context
4. **Publishes** enriched data to Kafka topics for analytics and monitoring

## Services

| Service | Purpose | Ports |
|---------|---------|-------|
| **Mosquitto** | MQTT broker for receiving OPC UA data | 1883 |
| **Redis** | Key-value store for production context | 6379, 8001 (RedisInsight) |
| **Redpanda** | Kafka-compatible streaming platform | 19092 (Kafka), 18081 (Schema Registry) |
| **Redpanda Console** | Web UI for Kafka topics and messages | 8080 |
| **Redis Hydration** | Syncs MQTT data to Redis hash maps | - |
| **Enrichment Pipeline** | Enriches metrics with production context | - |
| **Availability Pipeline** | Simple MQTT to Kafka passthrough | - |

## Prerequisites

- Docker and Docker Compose
- Running OPC UA server (see BeverageFillingLineOpcServer)
- Running OPC-MQTT bridge (see BeverageFillingLineOpcMqttBridge)

## Quick Start

1. **Create required directories:**
```bash
mkdir -p mosquitto/config mosquitto/data mosquitto/log redis/data
```

2. **Create Mosquitto configuration:**
```bash
echo "listener 1883" > mosquitto/config/mosquitto.conf
echo "allow_anonymous true" >> mosquitto/config/mosquitto.conf
```

3. **Start all services:**
```bash
docker-compose up -d
```

4. **Verify services are running:**
```bash
docker-compose ps
```

## Data Flow

```
OPC UA Server → MQTT Bridge → MQTT Broker (Mosquitto)
                                    ↓
                           ┌────────┴────────┐
                           ↓                 ↓
                    Redis Hydration   Enrichment Pipeline
                           ↓                 ↓
                    Redis Cache       Kafka (Redpanda)
                           ↑                 ↓
                           └─────────────────┘
```

## Access Points

- **RedisInsight**: http://localhost:8001 - Browse Redis data
- **Redpanda Console**: http://localhost:8080 - View Kafka topics and messages
- **Kafka API**: localhost:19092 - Connect applications
- **MQTT Broker**: localhost:1883 - Publish/subscribe to topics

## Kafka Topics

- `beverage_filling_raw` - Raw MQTT data without enrichment
- `beverage_filling_enriched` - Metrics enriched with production context from Redis

## UNS Topic Structure

The system follows Unified Namespace (UNS) conventions:
```
v1/best-beverage/dornbirn/production/filling-line-1/{metric_name}
```

## Redis Data Structure

Production context is stored in Redis as hash maps with the line identifier as the key:
- Key: `filling-line-1`
- Fields: `production_order`, `production_article`, `machine_name`, `machine_serial_number`, etc.

## Enrichment Process

The enrichment pipeline:
1. Subscribes to key MQTT metrics (machine_status, fill_volume, alarms, counters)
2. Extracts line identifier from the MQTT topic
3. Looks up production context from Redis using the line identifier
4. Combines metric data with production context
5. Publishes enriched messages to Kafka

## Stopping Services

```bash
docker-compose down
```

To remove all data:
```bash
docker-compose down -v
```

## Monitoring

View logs for any service:
```bash
docker-compose logs -f <service_name>
```

Example:
```bash
docker-compose logs -f enrichment_pipeline
```