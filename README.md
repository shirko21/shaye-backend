# shaye-backend

Backend API for SHAYE, built with Express and PostgreSQL.

## Authentication contract

Registration and login only ask the user for an email address and password.

### Register

`POST /api/auth/register`

```json
{
  "email": "user@example.com",
  "password": "minimum-8-characters"
}
```

Required fields: `email` and `password`. Internal display-name and username
values are generated automatically so they do not need to appear in the form.

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
The optional referral code remains a frontend-only field until referral support
is added to the backend. While registration is local, a non-empty code must
match an existing user's referral code or registration is rejected.
