# Docker Services

Data infrastructure stack for receiving and storing process data from the OPC UA bridge.

**1. Mosquitto MQTT Broker**
- Receives messages from OPC UA bridge (port 1883)
- Distributes data to subscribers
- WebSocket support on port 9001

**2. Redis Stack**
- Stores current state of all metrics (port 6379)
- RedisInsight web UI for visualization (port 8001)
- Data organized by production line

**3. Redis Hydration (Redpanda Connect)**
- Subscribes to MQTT topics
- Transforms messages and writes to Redis
- Maps UNS topics to Redis hash structures


```
OPC UA Bridge → MQTT Broker → Redis Hydration → Redis
                    ↓
              Subscribers
```

The bridge publishes 42 metrics to MQTT. Redis Hydration listens to these MQTT messages and stores them in Redis, grouped by production line.

**Example:**
- Topic: `v1/best-beverage/vienna/production/filling-line-1/machine_status`
- Redis: Key `filling-line-1`, Field `machine_status`, Value `{"timestamp":"...","value":"Running"}`

## Setup

### Directory Structure
```bash
mkdir -p mosquitto/{config,data,log} redis/data
```

### Files Needed
- `docker-compose.yml` - Service definitions
- `redis_hydration.yaml` - MQTT to Redis pipeline config
- `mosquitto/config/mosquitto.conf` - MQTT broker config

## Usage

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose stop

# Restart services
docker-compose restart
```

## Verify It's Working

**Check MQTT:**
```bash
mosquitto_sub -h localhost -t "#" -v
```

**Check Redis:**
```bash
docker exec -it redis redis-cli
> HGETALL filling-line-1
```

**Access RedisInsight:**
Open browser to `http://localhost:8001`