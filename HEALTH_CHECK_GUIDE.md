# Health Check Implementation Guide

This guide explains how to implement the `/health` endpoint required by the CI/CD pipeline.

## Why Health Checks Matter

Health checks are critical for:
- **Load Balancer**: Determines which tasks receive traffic
- **Docker Container**: Kubernetes-style liveness probes
- **Auto-Scaling**: Verifies healthy instances before processing traffic
- **Deployment Verification**: Confirms service is operational after deployment

## Health Check Configuration

### Docker Healthcheck

The Dockerfile includes:
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

**Parameters**:
- `interval=30s`: Check every 30 seconds
- `timeout=5s`: Fail if no response within 5 seconds
- `start-period=10s`: Allow 10 seconds for startup
- `retries=3`: Mark unhealthy after 3 consecutive failures

### ALB Health Check

Terraform configuration:
```hcl
health_check {
  healthy_threshold   = 2      # 2 consecutive successes = healthy
  unhealthy_threshold = 3      # 3 consecutive failures = unhealthy
  timeout             = 5      # 5 second timeout
  interval            = 30     # Check every 30 seconds
  path                = "/health"
  matcher             = "200,301,302"  # Accepted HTTP status codes
}
```

## Implementing Health Endpoint

### Node.js/Express Implementation

Add this to your `backend/server.js`:

```javascript
const express = require('express');
const app = express();

// =====================================================================
// HEALTH CHECK ENDPOINTS
// =====================================================================

/**
 * Liveness Probe - Is the application running?
 * Used by: Docker, ECS, Kubernetes
 * Returns: 200 if running, 503 if degraded
 */
app.get('/health', (req, res) => {
  // Basic health check - just confirm app is running
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

/**
 * Readiness Probe - Is the application ready to accept traffic?
 * Used by: Load balancers, Kubernetes
 * Returns: 200 if ready, 503 if not ready
 */
app.get('/health/ready', (req, res) => {
  // Check if all dependencies are available
  // Add checks for: database, cache, external services, etc.
  
  const readiness = {
    status: 'ready',
    timestamp: new Date().toISOString(),
    checks: {
      database: checkDatabase(),
      cache: checkCache(),
      externalApi: checkExternalApi()
    }
  };

  // Determine overall readiness
  const allHealthy = Object.values(readiness.checks).every(check => check.healthy);
  
  if (allHealthy) {
    res.status(200).json(readiness);
  } else {
    res.status(503).json({
      ...readiness,
      status: 'not_ready'
    });
  }
});

/**
 * Detailed Health Check - Full system status
 * Used by: Monitoring, dashboards, manual verification
 * Returns: 200 with detailed metrics
 */
app.get('/health/deep', (req, res) => {
  const deepHealth = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: {
      heapUsed: process.memoryUsage().heapUsed,
      heapTotal: process.memoryUsage().heapTotal,
      external: process.memoryUsage().external,
      rss: process.memoryUsage().rss
    },
    cpu: process.cpuUsage(),
    environment: {
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch
    },
    dependencies: {
      database: checkDatabase(),
      cache: checkCache(),
      externalApi: checkExternalApi()
    }
  };

  res.status(200).json(deepHealth);
});

/**
 * Dependency Check Functions
 * Implement these based on your actual dependencies
 */

function checkDatabase() {
  // Implement actual database connection check
  // Example:
  // try {
  //   const result = await db.query('SELECT 1');
  //   return { healthy: true, latency: result.latency };
  // } catch (error) {
  //   return { healthy: false, error: error.message };
  // }
  
  return {
    healthy: true,
    latency: 1,
    type: 'mongodb'
  };
}

function checkCache() {
  // Implement actual cache check (Redis, etc.)
  // Example:
  // try {
  //   const result = await redis.ping();
  //   return { healthy: result === 'PONG', type: 'redis' };
  // } catch (error) {
  //   return { healthy: false, error: error.message };
  // }
  
  return {
    healthy: true,
    latency: 0,
    type: 'redis'
  };
}

function checkExternalApi() {
  // Implement external service health check
  // Example:
  // try {
  //   const response = await fetch('https://api.example.com/health');
  //   return { healthy: response.ok, status: response.status };
  // } catch (error) {
  //   return { healthy: false, error: error.message };
  // }
  
  return {
    healthy: true,
    latency: 50,
    endpoint: 'api.example.com'
  };
}

// =====================================================================
// GRACEFUL SHUTDOWN
// =====================================================================

let isShuttingDown = false;

// Update health check during shutdown
app.get('/health', (req, res) => {
  if (isShuttingDown) {
    res.status(503).json({
      status: 'shutting_down',
      timestamp: new Date().toISOString()
    });
  } else {
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  }
});

// Handle shutdown signals
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  isShuttingDown = true;

  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    console.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 30000);
});

// =====================================================================
// SERVER STARTUP
// =====================================================================

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});

module.exports = { app, server };
```

## Advanced Health Check with Metrics

For production environments, integrate with monitoring:

```javascript
const prometheus = require('prom-client');

// Create metrics
const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const healthCheckDuration = new prometheus.Histogram({
  name: 'health_check_duration_seconds',
  help: 'Duration of health checks'
});

// Enhanced health endpoint
app.get('/health', async (req, res) => {
  const timer = healthCheckDuration.startTimer();

  try {
    const health = await performHealthChecks();
    
    const status = health.allHealthy ? 200 : 503;
    res.status(status).json(health);
    
    httpRequestsTotal.labels('GET', '/health', status).inc();
    timer();
  } catch (error) {
    console.error('Health check error:', error);
    res.status(503).json({
      status: 'error',
      error: error.message
    });
    
    httpRequestsTotal.labels('GET', '/health', 503).inc();
    timer();
  }
});

// Prometheus metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(prometheus.register.metrics());
});

async function performHealthChecks() {
  const checks = await Promise.all([
    checkDatabase(),
    checkCache(),
    checkExternalApi()
  ]);

  return {
    status: checks.every(c => c.healthy) ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    checks: {
      database: checks[0],
      cache: checks[1],
      externalApi: checks[2]
    },
    allHealthy: checks.every(c => c.healthy)
  };
}
```

## Testing Health Endpoints

### Manual Testing

```bash
# Liveness check
curl -v http://localhost:3000/health

# Readiness check
curl -v http://localhost:3000/health/ready

# Deep health check
curl -v http://localhost:3000/health/deep

# Expected 200 response
curl -w "\n%{http_code}\n" http://localhost:3000/health
```

### Integration Testing

```javascript
// backend/tests/health.test.js
const request = require('supertest');
const { app } = require('../server');

describe('Health Check Endpoints', () => {
  
  test('GET /health returns 200', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe('healthy');
  });

  test('GET /health/ready returns 200 when ready', async () => {
    const response = await request(app).get('/health/ready');
    expect(response.statusCode).toBe(200);
    expect(response.body.checks).toBeDefined();
  });

  test('GET /health/deep includes memory metrics', async () => {
    const response = await request(app).get('/health/deep');
    expect(response.statusCode).toBe(200);
    expect(response.body.memory).toBeDefined();
    expect(response.body.memory.heapUsed).toBeGreaterThan(0);
  });

  test('Health check includes timestamp', async () => {
    const response = await request(app).get('/health');
    expect(response.body.timestamp).toBeDefined();
    expect(new Date(response.body.timestamp)).toBeInstanceOf(Date);
  });

  test('Health check includes uptime', async () => {
    const response = await request(app).get('/health');
    expect(response.body.uptime).toBeGreaterThan(0);
  });
});
```

### Cypress E2E Test

```javascript
// cypress/e2e/health.cy.js
describe('Health Checks', () => {
  
  beforeEach(() => {
    cy.visit('/');
  });

  it('should have a working health endpoint', () => {
    cy.request('/health').then((response) => {
      expect(response.status).to.equal(200);
      expect(response.body).to.have.property('status', 'healthy');
    });
  });

  it('should return JSON from health endpoint', () => {
    cy.request('/health').then((response) => {
      expect(response.headers['content-type']).to.include('application/json');
      expect(response.body.timestamp).to.exist;
      expect(response.body.uptime).to.be.a('number');
    });
  });

  it('should have low health check latency', () => {
    const start = Date.now();
    cy.request('/health').then(() => {
      const duration = Date.now() - start;
      expect(duration).to.be.lessThan(1000); // Should respond within 1 second
    });
  });
});
```

## Monitoring Health Checks

### CloudWatch Logs Insights

Query health check patterns:

```
fields @timestamp, @message, @duration
| filter @message like /health/
| stats count() as health_checks, avg(@duration) as avg_duration by bin(5m)
```

### Grafana Dashboard

Create dashboard panels:

```json
{
  "dashboard": {
    "title": "Application Health",
    "panels": [
      {
        "title": "Health Check Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, health_check_duration_seconds)"
          }
        ]
      },
      {
        "title": "Health Check Failures",
        "targets": [
          {
            "expr": "increase(http_requests_total{route=\"/health\",status=\"503\"}[5m])"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### Health Check Failures

**Symptom**: ALB reporting unhealthy targets

**Solution**:
1. Check application logs for errors
2. Verify health endpoint is responding
3. Check network connectivity and security groups
4. Verify health check path in ALB configuration

```bash
# Test health endpoint from container
docker exec <container_id> curl -f http://localhost:3000/health
```

### Slow Health Checks

**Symptom**: Timeout errors in health checks

**Solution**:
1. Optimize dependency checks
2. Increase timeout in Dockerfile/ALB
3. Make checks non-blocking
4. Cache results temporarily

### Cascading Failures

**Symptom**: One failed dependency marks entire service unhealthy

**Solution**:
1. Use circuit breakers for external services
2. Return degraded status instead of failure
3. Implement fallback mechanisms
4. Make optional checks non-fatal

