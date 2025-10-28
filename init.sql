-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create main metrics table
CREATE TABLE IF NOT EXISTS beverage_metrics (
    time TIMESTAMPTZ NOT NULL,
    metric VARCHAR(100) NOT NULL,
    line VARCHAR(50) NOT NULL,
    value DOUBLE PRECISION,
    production_order VARCHAR(100),
    article VARCHAR(100),
    machine_name VARCHAR(100),
    plant VARCHAR(100)
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('beverage_metrics', 'time', if_not_exists => TRUE);

-- Add retention policy: keep data for 90 days
SELECT add_retention_policy('beverage_metrics', INTERVAL '90 days', if_not_exists => TRUE);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_metric_line_time ON beverage_metrics (metric, line, time DESC);
CREATE INDEX IF NOT EXISTS idx_production_order ON beverage_metrics (production_order, time DESC);

-- ============================================
-- CONTINUOUS AGGREGATE: Hourly KPIs
-- ============================================
CREATE MATERIALIZED VIEW IF NOT EXISTS hourly_kpis
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS hour,
    line,
    metric,
    production_order,
    article,
    machine_name,
    plant,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    STDDEV(value) as stddev_value,
    COUNT(*) as sample_count
FROM beverage_metrics
GROUP BY hour, line, metric, production_order, article, machine_name, plant;

-- Add refresh policy for hourly aggregates
SELECT add_continuous_aggregate_policy('hourly_kpis',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '30 minutes',
    if_not_exists => TRUE);

-- ============================================
-- CONTINUOUS AGGREGATE: Daily KPIs
-- ============================================
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_kpis
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    line,
    metric,
    production_order,
    article,
    machine_name,
    plant,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    STDDEV(value) as stddev_value,
    COUNT(*) as sample_count
FROM beverage_metrics
GROUP BY day, line, metric, production_order, article, machine_name, plant;

-- Add refresh policy for daily aggregates
SELECT add_continuous_aggregate_policy('daily_kpis',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '6 hours',
    if_not_exists => TRUE);

-- ============================================
-- Useful views
-- ============================================
CREATE OR REPLACE VIEW latest_metrics AS
SELECT DISTINCT ON (line, metric)
    time,
    line,
    metric,
    value,
    production_order,
    article,
    machine_name,
    plant
FROM beverage_metrics
ORDER BY line, metric, time DESC;