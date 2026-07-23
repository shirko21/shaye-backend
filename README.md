# shaye-backend

Backend API for SHAYE, built with Express and PostgreSQL.

## Authentication contract

Registration and login only ask the user for an email address and password.

### Register

`POST /api/auth/register`

```json
{
  "email": "user@example.com",
  "password": "minimum-8-characters",
  "inviteCode": "SH..."
}
```

Required fields: `email` and `password`. Internal display-name and username
values are generated automatically so they do not need to appear in the form.
`inviteCode` is optional, but a non-empty value must match an active user's
server-generated referral code. Successful registration returns both `token`
and a sanitized `user` object.

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

### Verify password

`POST /api/auth/verify-password` requires `Authorization: Bearer <token>` and
accepts `{ "password": "..." }`. The frontend uses it for sensitive actions
without keeping a plaintext password in browser storage.

## Current scope

Authentication, session tokens, referral-code validation and password checks
are server-backed. Existing finance, task and team screens still cache their
prototype data locally until their dedicated API endpoints are implemented.

## Hosted database configuration

For Neon or another hosted PostgreSQL provider, set the complete connection
string as the `DATABASE_URL` environment variable. Set a strong, private
`JWT_SECRET` as a separate environment variable. The server applies the
idempotent schema initialization before it starts listening for requests.

The individual `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME`
variables remain available as a local-development fallback. Set `DB_SSL=false`
only when the local database does not support SSL.
