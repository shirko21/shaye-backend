CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,

    fullname VARCHAR(100) NOT NULL,

    username VARCHAR(50) UNIQUE NOT NULL,

    email VARCHAR(150) UNIQUE NOT NULL,

    password VARCHAR(255) NOT NULL,

    phone VARCHAR(20),

    balance NUMERIC(20,2) DEFAULT 0,

    vip BOOLEAN DEFAULT FALSE,

    is_admin BOOLEAN DEFAULT FALSE,

    status VARCHAR(20) DEFAULT 'active',

    referral_code VARCHAR(32) UNIQUE NOT NULL,

    referred_by INTEGER REFERENCES users(id) ON DELETE SET NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Idempotent upgrade for databases created before referral support.
ALTER TABLE users
ADD COLUMN IF NOT EXISTS referral_code VARCHAR(32);

ALTER TABLE users
ADD COLUMN IF NOT EXISTS referred_by INTEGER REFERENCES users(id) ON DELETE SET NULL;

UPDATE users
SET referral_code =
  'SH' || UPPER(SUBSTRING(MD5(id::text || email || created_at::text) FROM 1 FOR 16))
WHERE referral_code IS NULL OR referral_code = '';

CREATE UNIQUE INDEX IF NOT EXISTS users_referral_code_unique
ON users (referral_code);

ALTER TABLE users
ALTER COLUMN referral_code SET NOT NULL;
