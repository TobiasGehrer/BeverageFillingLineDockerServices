# Mosquitto MQTT Broker

MQTT message broker that receives data from the OPC UA bridge and distributes it to subscribers.

## What It Does

Mosquitto acts as a message hub:
1. Receives messages from the OPC UA bridge
2. Stores them temporarily
3. Forwards them to any subscribers (MQTT Explorer, dashboards, analytics tools)

It runs on port **1883** and handles ~5 messages every 3 seconds from the bridge.

## Setup

### Directory Structure

```bash
mkdir -p mosquitto-mqtt/mosquitto/{config,data,log}
cd mosquitto-mqtt
```

### Create `mosquitto/config/mosquitto.conf`

```conf
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_dest stdout

listener 1883
protocol mqtt
allow_anonymous true

listener 9001
protocol websockets
allow_anonymous true
```

### Create `docker-compose.yml`

```yaml
version: '3.8'

services:
  mosquitto:
    image: eclipse-mosquitto:latest
    container_name: mosquitto-broker
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
    restart: unless-stopped
```

## Usage

```bash
# Start
docker-compose up -d

# Check status
docker ps | grep mosquitto

# View logs
docker logs mosquitto-broker

# Stop
docker-compose stop
```

## Testing

```bash
# Subscribe to all topics
mosquitto_sub -h localhost -t "#" -v

# Test publish
mosquitto_pub -h localhost -t "test" -m "Hello"
```