# Ecommerce Service API

A Rails 8 API-only application with JWT authentication using Devise.

## Ruby version
- Ruby 3.x
- Rails 8.0

## System dependencies
- PostgreSQL
- Redis (for caching and sessions)

## Configuration
1. Clone the repository
2. Install dependencies: `bundle install`
3. Setup database: `rails db:create db:migrate db:seed`
4. Start the server: `rails server`

## Authentication API

### Base URL
```
http://localhost:3000
```

### Register User
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123",
      "name": "John Doe"
    }
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123"
    }
  }'
```

Response includes JWT token in Authorization header.

### Logout
```bash
curl -X DELETE http://localhost:3000/auth/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Refresh Token
```bash
curl -X POST http://localhost:3000/auth/refresh_tokens \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "refresh_token": "YOUR_JWT_TOKEN"
    }
  }'
```

### Get User Profile
```bash
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Request Password Reset
```bash
curl -X POST http://localhost:3000/auth/forgot_password \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com"
    }
  }'
```

### Reset Password (with token from email)
```bash
curl -X PATCH http://localhost:3000/auth/change_password \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "reset_password_token": "TOKEN_FROM_EMAIL",
      "password": "newpassword123",
      "password_confirmation": "newpassword123"
    }
  }'
```


## Features
- JWT Authentication with Devise
- Token refresh with automatic revocation
- Password reset via email
- User profile management
- Secure token blacklisting
- Service object architecture
- Comprehensive error handling

## Security Features
- JWT tokens with 1-day expiration
- Token blacklisting on refresh for security
- Password reset tokens with expiration
- CORS configuration for frontend integration
- Secure password validation

## Development

### Database creation
```bash
rails db:create
rails db:migrate
rails db:seed
```

### How to run the test suite
```bash
rails test
```

### Background Jobs
Uses Solid Queue for background job processing. Jobs are configured in `config/queue.yml` and recurring jobs in `config/recurring.yml`.

### Services
- JWT token management
- Email notifications
- Background job processing with Solid Queue

## Deployment
- Configure environment variables for JWT secret and database
- Set up PostgreSQL database
- Configure email delivery for password resets
- Deploy with your preferred platform (Heroku, Docker, etc.)
