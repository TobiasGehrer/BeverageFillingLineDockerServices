# Beverage Filling Line - Startup Guide

## Prerequisites
- .NET 8.0 SDK
- Docker Desktop

## Folder Structure
```
Datenbanken/
├── BeverageFillingLineOpcServer/
├── BeverageFillingLineOpcMqttBridge/
├── BeverageFillingLineDockerServices/
└── BeverageFillingLineKafkaTimescaledbBridge/
```

## Startup Sequence

### 1. Start Docker Services
```bash
cd Datenbanken/BeverageFillingLineDockerServices
docker-compose up -d
```

Wait 30 seconds for all services to initialize.

**Verify services are running:**
```bash
docker-compose ps
```

### 2. Start OPC UA Server
```bash
cd Datenbanken/BeverageFillingLineOpcServer
dotnet run
```

**Expected output:**
```
Server started at: opc.tcp://localhost:4840
Press any key to exit...
```

### 3. Start OPC-MQTT Bridge
Open a new terminal:
```bash
cd Datenbanken/BeverageFillingLineOpcMqttBridge
dotnet run
```

**Expected output:**
```
Connected to OPC UA server
Connected to MQTT broker
Bridge active. Publishing every 3 seconds...
```

### 4. Start Kafka-TimescaleDB Bridge
Open a new terminal:
```bash
cd Datenbanken/BeverageFillingLineKafkaTimescaledbBridge
dotnet run
```

**Expected output:**
```
✓ Database connection successful
Subscribed to topic: beverage_metrics
[HH:mm:ss] Processed X messages (batch: 100)
```

## Web Interfaces

| Interface | URL | Credentials |
|-----------|-----|-------------|
| Redpanda Console | http://localhost:8080 | None |
| RedisInsight | http://localhost:8001 | None |
| pgAdmin | http://localhost:5050 | admin@admin.com / admin123 |

## Verify Data Flow

### 1. Check MQTT Messages (Redpanda Console)
- Open: http://localhost:8080
- Go to: **Topics** → `beverage_metrics`
- Should see messages flowing

### 2. Check Redis (RedisInsight)
- Open: http://localhost:8001
- Connect to: `localhost:6379`
- Browse key: `filling-line-1`
- Should see ~40 fields with latest values

### 3. Check Database (pgAdmin)
- Open: http://localhost:5050
- Login: `admin@admin.com` / `admin123`
- **First time only:** Add server:
  - Name: TimescaleDB
  - Host: `timescaledb`
  - Port: 5432
  - Database: `beverage_data`
  - User: `admin`
  - Password: `admin123`

**Run test query:**
```sql
SELECT COUNT(*), MAX(time) FROM beverage_metrics;
```

Should show growing record count.

## Shutdown

### Stop all services:
```bash
# Stop .NET applications (in each terminal)
Ctrl + C

# Stop Docker services
cd Datenbanken/BeverageFillingLineDockerServices
docker-compose down
```

### Remove all data (optional):
```bash
docker-compose down -v
```

## Troubleshooting

**No data in database?**
1. Check all 4 applications are running
2. Verify Kafka has messages: http://localhost:8080 → Topics
3. Check C# bridge logs for errors

**Container keeps restarting?**
```bash
docker-compose logs [container-name]
```

**Port already in use?**
```bash
# Check what's using the port
netstat -ano | findstr :1883
netstat -ano | findstr :5432
```

## Normal Startup Order
1. Docker (30s)
2. OPC Server (instant)
3. OPC-MQTT Bridge (instant)
4. Kafka-TimescaleDB Bridge (instant)

**Total startup time: ~1 minute**