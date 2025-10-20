# Sample App API Documentation

## Overview

The sample application provides a RESTful API for managing users, products, and orders. All endpoints support distributed tracing and structured logging.

## Base URL

```
http://sample-app.default.svc.cluster.local
```

## Endpoints

### Root

#### GET /

Returns API information and available endpoints.

**Response:**
```json
{
  "message": "GitOps Sample App with Observability",
  "version": "1.0.0",
  "endpoints": [...]
}
```

### Health Check

#### GET /health

Health check endpoint with dependency status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "dependencies": {
    "database": "healthy",
    "cache": "healthy"
  }
}
```

## Users API

### List Users

#### GET /api/users

Returns all users.

**Response:**
```json
[
  {
    "id": 1,
    "name": "Alice Johnson",
    "email": "alice@example.com"
  },
  ...
]
```

### Get User

#### GET /api/users/{id}

Get user by ID.

**Parameters:**
- `id` (path, integer): User ID

**Response:**
```json
{
  "id": 1,
  "name": "Alice Johnson",
  "email": "alice@example.com"
}
```

**Error Responses:**
- `404 Not Found`: User not found

### Create User

#### POST /api/users

Create a new user.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "id": 4,
  "name": "John Doe",
  "email": "john@example.com"
}
```

## Products API

### List Products

#### GET /api/products

Returns all products.

**Query Parameters:**
- `search` (optional, string): Search term to filter products

**Response:**
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "price": 999.99,
    "stock": 50
  },
  ...
]
```

### Get Product

#### GET /api/products/{id}

Get product by ID.

**Parameters:**
- `id` (path, integer): Product ID

**Response:**
```json
{
  "id": 1,
  "name": "Laptop",
  "price": 999.99,
  "stock": 50
}
```

**Error Responses:**
- `404 Not Found`: Product not found

## Orders API

### List Orders

#### GET /api/orders

Returns all orders.

**Response:**
```json
[
  {
    "id": 1,
    "userId": 1,
    "userName": "Alice Johnson",
    "productId": 1,
    "productName": "Laptop",
    "quantity": 2,
    "totalPrice": 1999.98,
    "orderDate": "2024-01-15T10:30:00Z",
    "status": "Confirmed"
  },
  ...
]
```

### Create Order

#### POST /api/orders

Create a new order.

**Request Body:**
```json
{
  "userId": 1,
  "productId": 1,
  "quantity": 2
}
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "userName": "Alice Johnson",
  "productId": 1,
  "productName": "Laptop",
  "quantity": 2,
  "totalPrice": 1999.98,
  "orderDate": "2024-01-15T10:30:00Z",
  "status": "Confirmed"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid user, product, or insufficient stock

## Testing Endpoints

### Slow Request

#### GET /api/slow

Simulates a slow request (2-5 seconds delay) for testing latency alerts.

**Response:**
```json
{
  "message": "Slow operation completed",
  "delayMs": 3500
}
```

### Error Simulation

#### GET /api/error

Triggers an exception for testing error alerts.

**Response:**
- `500 Internal Server Error`

## Observability

### Correlation IDs

All requests support correlation IDs via the `X-Correlation-ID` header. If not provided, one is automatically generated.

**Request:**
```bash
curl -H "X-Correlation-ID: my-trace-123" http://sample-app/api/users
```

**Response Header:**
```
X-Correlation-ID: my-trace-123
```

### Distributed Tracing

All endpoints are instrumented with OpenTelemetry. Traces include:
- HTTP method and path
- Response status code
- Duration
- Correlation ID
- Custom tags (user_id, product_id, etc.)

### Structured Logging

All requests generate structured JSON logs with:
- Timestamp
- Log level
- Message
- Trace ID
- Span ID
- Correlation ID

## Examples

### Browse Products and Create Order

```bash
# List products
curl http://sample-app/api/products

# Search for laptop
curl http://sample-app/api/products?search=Laptop

# Get specific product
curl http://sample-app/api/products/1

# Create order
curl -X POST http://sample-app/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 1, "quantity": 2}'

# View orders
curl http://sample-app/api/orders
```

### Test Observability

```bash
# Generate slow request
curl http://sample-app/api/slow

# Generate error
curl http://sample-app/api/error

# Check health
curl http://sample-app/health
```

## Rate Limiting

Currently no rate limiting is implemented. The load generator creates realistic traffic patterns for testing.

## Authentication

Currently no authentication is required. This is a demo application for observability testing.
