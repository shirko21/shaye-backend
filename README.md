# shaye-backend

Backend API for SHAYE, built with Express and PostgreSQL.

## Authentication contract

The frontend and backend use the same fields for registration and login.

### Register

`POST /api/auth/register`

```json
{
  "fullname": "Example User",
  "username": "example_user",
  "email": "user@example.com",
  "phone": "+989123456789",
  "password": "minimum-8-characters"
}
```

Required fields: `fullname`, `username`, `email`, and `password`.
`phone` is optional. Usernames are normalized to lowercase.

### Login

`POST /api/auth/login`

```json
{
  "email": "user@example.com",
  "password": "minimum-8-characters"
}
```

Successful login returns a JWT in `token` and a sanitized `user` object.
Password hashes are never included in API responses.

## Current scope

The frontend still stores users locally until the API-client integration phase.
The referral code remains a frontend-only field until referral support is added
to the backend.
