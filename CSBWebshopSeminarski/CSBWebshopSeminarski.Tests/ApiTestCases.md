# CSB Webshop API Test Cases

This document contains detailed test cases for the CSB Webshop backend API endpoints.

## Table of Contents
1. [Authentication API](#authentication-api)
2. [Bags API](#bags-api)
3. [Belts API](#belts-api)
4. [Orders API](#orders-api)
5. [Giveaways API](#giveaways-api)
6. [Recommendations API](#recommendations-api)
7. [RabbitMQ Event Flow](#rabbitmq-event-flow)

---

## Authentication API

### POST /api/auth/login

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-AUTH-001 | Successful login with valid credentials | User exists in database | `{"username": "testuser", "password": "Test123!"}` | 200 OK with JWT token, userId, roles | Pending |
| TC-API-AUTH-002 | Login with invalid username | - | `{"username": "nonexistent", "password": "Test123!"}` | 401 Unauthorized | Pending |
| TC-API-AUTH-003 | Login with invalid password | User exists | `{"username": "testuser", "password": "wrongpass"}` | 401 Unauthorized | Pending |
| TC-API-AUTH-004 | Login with empty username | - | `{"username": "", "password": "Test123!"}` | 400 Bad Request | Pending |
| TC-API-AUTH-005 | Login with empty password | - | `{"username": "testuser", "password": ""}` | 400 Bad Request | Pending |
| TC-API-AUTH-006 | Login returns valid JWT token | User exists | Valid credentials | JWT token can be decoded and contains userId | Pending |
| TC-API-AUTH-007 | Login returns correct roles | Admin user exists | Admin credentials | Roles array contains "Admin" | Pending |

### POST /api/auth/register

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-AUTH-008 | Successful registration | Username not taken | `{"firstName": "Test", "lastName": "User", "email": "test@example.com", "username": "newuser", "password": "Test123!"}` | 200 OK with user data | Pending |
| TC-API-AUTH-009 | Registration with existing username | Username exists | Same username | 400 Bad Request "Username already exists" | Pending |
| TC-API-AUTH-010 | Registration with existing email | Email exists | Same email | 400 Bad Request "Email already exists" | Pending |
| TC-API-AUTH-011 | Registration with invalid email format | - | `{"email": "invalid-email"}` | 400 Bad Request validation error | Pending |
| TC-API-AUTH-012 | Registration with short password | - | `{"password": "123"}` | 400 Bad Request "Password must be at least 6 characters" | Pending |
| TC-API-AUTH-013 | Registration with missing required fields | - | Missing firstName | 400 Bad Request | Pending |
| TC-API-AUTH-014 | New user gets Buyer role | - | Valid registration data | User has "Buyer" role | Pending |

---

## Bags API

### GET /api/bags

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BAG-001 | Get all bags | Bags exist in DB | - | 200 OK with array of bags | Pending |
| TC-API-BAG-002 | Get bags with pagination | Multiple bags exist | `?page=1&pageSize=10` | 200 OK with 10 items max | Pending |
| TC-API-BAG-003 | Filter bags by type | Bags with types exist | `?bagTypeId=1` | Only bags of type 1 returned | Pending |
| TC-API-BAG-004 | Search bags by name | Bags exist | `?query=luxury` | Only bags with "luxury" in name | Pending |
| TC-API-BAG-005 | Get bags returns required fields | Bags exist | - | Each bag has id, name, code, price, description | Pending |
| TC-API-BAG-006 | Get bags returns averageRating | Bags with ratings exist | - | averageRating included in response | Pending |
| TC-API-BAG-007 | Empty result for no matches | - | `?query=nonexistent123` | 200 OK with empty array | Pending |

### GET /api/bags/{id}

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BAG-008 | Get bag by valid ID | Bag with ID 1 exists | `/api/bags/1` | 200 OK with bag details | Pending |
| TC-API-BAG-009 | Get bag by invalid ID | - | `/api/bags/99999` | 404 Not Found | Pending |
| TC-API-BAG-010 | Get bag includes image URL | Bag has image | `/api/bags/1` | imageUrl field populated | Pending |

### POST /api/bags (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BAG-011 | Create bag with valid data | Admin authenticated | `{"name": "New Bag", "code": "NB001", "price": 150.0}` | 201 Created | Pending |
| TC-API-BAG-012 | Create bag without admin role | Buyer authenticated | Valid bag data | 403 Forbidden | Pending |
| TC-API-BAG-013 | Create bag with missing name | Admin authenticated | Missing name field | 400 Bad Request | Pending |
| TC-API-BAG-014 | Create bag with negative price | Admin authenticated | `{"price": -50}` | 400 Bad Request | Pending |
| TC-API-BAG-015 | Create bag with base64 image | Admin authenticated | imageBase64 included | Bag created with image | Pending |

### PUT /api/bags/{id} (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BAG-016 | Update bag with valid data | Bag exists, Admin auth | Updated fields | 200 OK with updated bag | Pending |
| TC-API-BAG-017 | Update non-existent bag | Admin authenticated | Invalid ID | 404 Not Found | Pending |
| TC-API-BAG-018 | Update bag without admin role | Buyer authenticated | Valid data | 403 Forbidden | Pending |

### DELETE /api/bags/{id} (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BAG-019 | Delete bag successfully | Bag exists, Admin auth | Valid ID | 204 No Content | Pending |
| TC-API-BAG-020 | Delete non-existent bag | Admin authenticated | Invalid ID | 404 Not Found | Pending |
| TC-API-BAG-021 | Delete bag without admin role | Buyer authenticated | Valid ID | 403 Forbidden | Pending |

---

## Belts API

### GET /api/belts

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BELT-001 | Get all belts | Belts exist in DB | - | 200 OK with array of belts | Pending |
| TC-API-BELT-002 | Filter belts by type | Belts with types exist | `?beltTypeId=1` | Only belts of type 1 returned | Pending |
| TC-API-BELT-003 | Search belts by name | Belts exist | `?query=leather` | Only belts with "leather" in name | Pending |

### GET /api/belts/{id}

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BELT-004 | Get belt by valid ID | Belt with ID 1 exists | `/api/belts/1` | 200 OK with belt details | Pending |
| TC-API-BELT-005 | Get belt by invalid ID | - | `/api/belts/99999` | 404 Not Found | Pending |

### POST/PUT/DELETE /api/belts (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-BELT-006 | Create belt with valid data | Admin authenticated | Valid belt data | 201 Created | Pending |
| TC-API-BELT-007 | Update belt successfully | Belt exists, Admin auth | Updated data | 200 OK | Pending |
| TC-API-BELT-008 | Delete belt successfully | Belt exists, Admin auth | Valid ID | 204 No Content | Pending |

---

## Orders API

### POST /api/orders

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-ORD-001 | Create order successfully | Authenticated user | `{"userId": 1}` | 201 Created with order number | Pending |
| TC-API-ORD-002 | Create order publishes RabbitMQ event | Authenticated user | Valid order data | Event published to `orders.created` | Pending |
| TC-API-ORD-003 | Create order without auth | Not authenticated | Valid order data | 401 Unauthorized | Pending |

### GET /api/orders/Active

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-ORD-004 | Get active cart for user | User has active cart | `?userId=1` | 200 OK with cart data | Pending |
| TC-API-ORD-005 | Get active cart when none exists | No active cart | `?userId=1` | 204 No Content | Pending |

### GET /api/orders/ByUser

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-ORD-006 | Get orders by user | User has orders | `?userId=1` | 200 OK with orders array | Pending |
| TC-API-ORD-007 | Get orders sorted by date | Multiple orders exist | `?userId=1` | Orders sorted by date descending | Pending |

### POST /api/orders/{id}/payment-intent

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-ORD-008 | Create Stripe payment intent | Valid order exists | Order ID | 200 OK with clientSecret | Pending |
| TC-API-ORD-009 | Payment intent for invalid order | - | Invalid order ID | 404 Not Found | Pending |

### PATCH /api/orders/{id}/payment-status

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-ORD-010 | Update payment status to paid | Order exists | `{"status": "paid"}` | 204 No Content | Pending |
| TC-API-ORD-011 | Update payment status for invalid order | - | Invalid ID | 404 Not Found | Pending |

---

## Giveaways API

### GET /api/giveaways

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-GIVE-001 | Get all giveaways | Giveaways exist | - | 200 OK with array | Pending |
| TC-API-GIVE-002 | Filter active giveaways | Active giveaways exist | `?status=active` | Only active giveaways | Pending |
| TC-API-GIVE-003 | Filter closed giveaways | Closed giveaways exist | `?status=closed` | Only closed giveaways | Pending |
| TC-API-GIVE-004 | Invalid status filter | - | `?status=invalid` | 400 Bad Request | Pending |

### POST /api/giveaways (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-GIVE-005 | Create giveaway successfully | Admin authenticated | `{"title": "Test", "startDate": "...", "endDate": "..."}` | 200 OK with created giveaway | Pending |
| TC-API-GIVE-006 | Create giveaway without admin | Buyer authenticated | Valid data | 403 Forbidden | Pending |
| TC-API-GIVE-007 | Create giveaway with missing title | Admin authenticated | Missing title | 400 Bad Request | Pending |

### POST /api/giveaways/{id}/participants

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-GIVE-008 | Register for giveaway | Active giveaway exists | `{"name": "Test", "email": "test@example.com"}` | 200 OK with participant | Pending |
| TC-API-GIVE-009 | Register with invalid email | Active giveaway | `{"email": "invalid"}` | 400 Bad Request | Pending |
| TC-API-GIVE-010 | Register for closed giveaway | Closed giveaway | Valid data | 400 Bad Request | Pending |
| TC-API-GIVE-011 | Duplicate registration | Already registered | Same email | 400 Bad Request | Pending |
| TC-API-GIVE-012 | Email is masked in response | - | Valid registration | Email shown as `m***@example.com` | Pending |

### POST /api/giveaways/{id}/draw (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-GIVE-013 | Draw winner successfully | Participants exist | Active giveaway ID | 200 OK with winner | Pending |
| TC-API-GIVE-014 | Draw winner with no participants | No participants | Giveaway ID | 404 Not Found "No participants" | Pending |
| TC-API-GIVE-015 | Draw winner closes giveaway | - | Valid draw | Giveaway.isClosed = true | Pending |
| TC-API-GIVE-016 | Draw winner without admin | Buyer authenticated | Giveaway ID | 403 Forbidden | Pending |

### POST /api/giveaways/{id}/announce-winner (Admin only)

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-GIVE-017 | Announce winner successfully | Winner exists | Giveaway ID | 200 OK with announcement result | Pending |
| TC-API-GIVE-018 | Announce creates news item | Winner exists | Giveaway ID | NewsItem created in DB | Pending |
| TC-API-GIVE-019 | Announce sends emails | Subscribers exist | Giveaway ID | Email sent to subscribers | Pending |
| TC-API-GIVE-020 | Announce without winner | No winner drawn | Giveaway ID | 400 Bad Request | Pending |

---

## Recommendations API

### GET /api/recommendations

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-API-REC-001 | Get recommendations with favorites | User has favorites | Authenticated request | 200 OK with recommended items | Pending |
| TC-API-REC-002 | Get recommendations without favorites | No favorites | Authenticated request | 200 OK with empty/default items | Pending |
| TC-API-REC-003 | Recommendations based on bag favorites | User favorited bags | Authenticated | Similar bags recommended | Pending |
| TC-API-REC-004 | Recommendations based on belt favorites | User favorited belts | Authenticated | Similar belts recommended | Pending |

---

## RabbitMQ Event Flow

### Order Created Event

| Test Case ID | Description | Preconditions | Test Data | Expected Result | Status |
|-------------|-------------|---------------|-----------|-----------------|--------|
| TC-MQ-001 | Order creation publishes event | RabbitMQ running | New order | Event on `orders.created` routing key | Pending |
| TC-MQ-002 | Event contains order details | - | New order | Event has orderId, userId, amount | Pending |
| TC-MQ-003 | Consumer receives event | Consumer running | New order | Consumer logs event receipt | Pending |
| TC-MQ-004 | Email sent on order creation | Email service configured | New order | Confirmation email sent to user | Pending |

---

## Test Execution Notes

### Prerequisites
1. Backend API running on configured port
2. Database seeded with test data
3. Valid JWT tokens for authenticated requests
4. RabbitMQ running for event tests
5. Stripe test mode configured for payment tests

### Test Data Requirements
- Admin user: `admin / Admin123!`
- Buyer user: `buyer / Buyer123!`
- Test bags with various types
- Test belts with various types
- Active and closed giveaways
- Sample orders with different statuses

### Authentication Header
All authenticated requests require:
```
Authorization: Bearer <jwt_token>
```

### Common Response Codes
- 200: Success
- 201: Created
- 204: No Content
- 400: Bad Request (validation error)
- 401: Unauthorized (not authenticated)
- 403: Forbidden (insufficient permissions)
- 404: Not Found
- 500: Server Error
