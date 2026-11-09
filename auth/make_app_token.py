"""
NelaBele – create tokens for the Neon Data API.

Neon's Data API only accepts requests that carry a signed token. This makes
a fresh signing key pair, adds its public half to auth/jwks.json (Neon
checks tokens against it), and prints a token.

Two kinds of token:

  --role anonymous      the app's read-only token. Ships inside the app, so
                        treat it as public. It can only read the api_* views.
  --role authenticated  an editor token for logging market rates. Keep it
                        private: anyone holding it can add rates.

Keys already in jwks.json are kept, so existing tokens keep working. The
private key is never saved. To revoke a token, delete its key (matched by
the token's "kid") from jwks.json and push.

Usage:
  pip install pyjwt cryptography
  python auth/make_app_token.py --role anonymous [--years 5]
  python auth/make_app_token.py --role authenticated --subject ramanaa [--years 2]
"""

import argparse
import base64
import json
import secrets
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
    ap.add_argument("--role", choices=["anonymous", "authenticated"], default="anonymous")
    ap.add_argument("--subject", default="nelabele-app", help="who the token is for")
    ap.add_argument("--years", type=int, default=5, help="token lifetime")
    args = ap.parse_args()

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pub = key.public_key().public_numbers()
    kid = f"nelabele-{args.role}-{time.strftime('%Y%m%d')}-{secrets.token_hex(3)}"

    path = Path(__file__).with_name("jwks.json")
    jwks = json.loads(path.read_text()) if path.exists() else {"keys": []}
    jwks["keys"].append({"kty": "RSA", "use": "sig", "alg": "RS256", "kid": kid,
                         "n": b64url(pub.n), "e": b64url(pub.e)})
    path.write_text(json.dumps(jwks, indent=2) + "\n")

    now = int(time.time())
    token = jwt.encode(
        {"role": args.role, "iss": ISSUER, "aud": AUDIENCE, "sub": args.subject,
         "iat": now, "exp": now + args.years * 365 * 24 * 3600},
        key, algorithm="RS256", headers={"kid": kid},
    )
    print(f"Added key {kid} to {path} ({len(jwks['keys'])} keys) – commit and push it")
    print(f"Role: {args.role}  Subject: {args.subject}  Valid for {args.years} years\n")
    print(token)


if __name__ == "__main__":
    main()
