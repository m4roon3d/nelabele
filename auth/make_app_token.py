"""
NelaBele – create the app's read-only key for the Neon Data API.

Neon's Data API only accepts requests that carry a signed token. This makes
a fresh signing key pair, publishes the public half as auth/jwks.json (Neon
checks tokens against it), and prints a long-lived token for the app.

The token only maps to the 'anonymous' database role, which can do nothing
but read the public api_* views and lookups. It ships inside the app, so
treat it as public. The private key is never saved: to rotate, run this
again, commit the new jwks.json and update the app's token.

Usage:
  pip install pyjwt cryptography
  python auth/make_app_token.py [--years 5]
"""

import argparse
import base64
import json
import time
from pathlib import Path

import jwt
from cryptography.hazmat.primitives.asymmetric import rsa

ISSUER = "nelabele"
AUDIENCE = "nelabele-data-api"


def b64url(n):
    raw = n.to_bytes((n.bit_length() + 7) // 8, "big")
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--years", type=int, default=5, help="token lifetime")
    args = ap.parse_args()

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pub = key.public_key().public_numbers()
    kid = f"nelabele-{time.strftime('%Y%m%d')}"

    jwks = {"keys": [{"kty": "RSA", "use": "sig", "alg": "RS256", "kid": kid,
                      "n": b64url(pub.n), "e": b64url(pub.e)}]}
    out = Path(__file__).with_name("jwks.json")
    out.write_text(json.dumps(jwks, indent=2) + "\n")

    now = int(time.time())
    token = jwt.encode(
        {"role": "anonymous", "iss": ISSUER, "aud": AUDIENCE, "sub": "nelabele-app",
         "iat": now, "exp": now + args.years * 365 * 24 * 3600},
        key, algorithm="RS256", headers={"kid": kid},
    )
    print(f"Wrote {out}")
    print(f"Issuer: {ISSUER}\nAudience: {AUDIENCE}\n\nApp token:\n{token}")


if __name__ == "__main__":
    main()
