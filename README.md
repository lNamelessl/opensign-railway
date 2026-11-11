# OpenSign — Self-Hosted Document Signing on Railway

One-click deploy of [OpenSign](https://github.com/OpenSignLabs/OpenSign), the open-source DocuSign alternative. Upload a PDF, place signature, date and text fields, send a signing link, and collect legally trackable signatures with a full audit trail and signing certificate — on your own Railway project.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/opensign-railway-creator)

## What you get

- **3 services, provisioned and wired automatically**: OpenSign Client (React SPA), OpenSign Server (Parse Server API with LibreOffice document conversion), and MongoDB.
- **Zero required variables** — every environment variable ships with a working default (secrets are generated per deploy via Railway secret references).
- **Signing works out of the box** — a shared self-signed signing certificate is preconfigured, so you can complete a full signature round-trip immediately.
- **Persistent by design** — MongoDB data and all uploaded/signed documents live on Railway volumes and survive redeploys.
- **Digest-pinned images** — deploys reference immutable image digests, not floating tags.

## How it works

| Service | Image | Port | Notes |
|---|---|---|---|
| Client | opensign/opensign (digest-pinned) | 3000 | React SPA served by a Node static server |
| Server | opensign/opensignserver (digest-pinned) | 8080 | Parse Server API, LibreOffice for DOCX to PDF |
| Mongo | mongo (digest-pinned) | 27017 | Private networking only |

The Client is deployed on its own public domain and calls the Server API cross-origin at `/app` (CORS is enabled server-side). The browser can only reach the Server through its public domain, so both app services get one; Mongo stays private.

## Configuration (all pre-filled, nothing required)

Everything deploys with working defaults — there are no required inputs. The Server variables are generated per deployment from Railway template expressions:

| Variable | Service | Default | Purpose |
|---|---|---|---|
| MASTER_KEY | Server | random 12-char secret per deployment | Parse Server master key |
| MONGODB_URI | Server | composed from the MongoDB service references (per-deploy credentials) | Database connection |
| SERVER_URL | Server | public domain of Server + /app | Public API URL |
| REACT_APP_SERVERURL | Client | public domain of Server + /app | API URL baked into the client at boot |
| MONGO_INITDB_ROOT_USERNAME / _PASSWORD | MongoDB | random secrets per deployment | Database root credentials |

Fixed settings (local storage mode, the signing certificate and its passphrase) are baked into the Server start command, so they ship with the template but can be changed later in the Server service settings.

Optional additions:

- **Email notifications (SMTP)**: set SMTP_ENABLE=true, SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASS, SMTP_USER_EMAIL on the Server. Without mail config everything still signs — but sign-request and completion emails are not sent, so share signing links manually from the UI, and password reset is unavailable. Port 465 uses implicit TLS, any other port uses STARTTLS. Mailgun works too via MAILGUN_API_KEY, MAILGUN_DOMAIN, MAILGUN_SENDER.
- **S3-compatible storage**: remove USE_LOCAL from the Server start command and set DO_SPACE, DO_ENDPOINT, DO_BASEURL, DO_ACCESS_KEY_ID, DO_SECRET_ACCESS_KEY, DO_REGION. The default uses the Server volume at /usr/src/app/files/files.

## Notes on the signing certificate

The template ships a shared self-signed P12 certificate (baked into the Server start command as PFX_BASE64, passphrase opensign) so signing and certificate generation work immediately. It is fine for trials and internal use. For production, upload your own certificate per organization inside OpenSign (Organisation settings), which overrides the bundled one. The bundled certificate was generated with the commands in cert/generate.sh.

# Deploy and Host

## About Hosting

This template provisions three services on Railway. The Server runs OpenSign's Parse Server (Node 22) with LibreOffice bundled for DOCX to PDF conversion — give it at least 1 GB of RAM; signature application and conversions are memory-hungry. Documents and uploads persist on a volume mounted at /usr/src/app/files/files on the Server; MongoDB persists on its own volume. On first boot the Server runs database migrations before it starts listening, so the first deploy can take a few minutes. Both app services expose healthcheck endpoints (/health on the Client, /app/health on the Server) and Railway restarts them automatically if they crash. Existing OpenSign templates on the marketplace show small deploy counts (1 and 7 deploys at publish time); this template differentiates with digest-pinned images, zero required variables, working signing on first boot, and verified volume persistence.

## Why Deploy

Manual self-hosting of OpenSign requires a reverse proxy (Caddy), a Mongo instance, runtime environment wiring between the React client and the Parse Server, and a signing certificate before the first signature can complete. This template does all of it: the client-to-API URL is wired via cross-service references, Mongo credentials flow through private networking, the signing certificate is preconfigured, and uploads land on a persistent volume. You get a working e-signature platform in one click instead of four hand-wired containers.

## Common Use Cases

- Signing contracts, NDAs, offer letters and vendor agreements with a full audit trail (IP addresses, timestamps, signing certificate).
- Sending documents to external signers who complete them from a public link without creating an account.
- Self-hosted DocuSign alternative where documents never leave your own infrastructure.
- Teams that need templates and bulk sending of reusable documents.

## Dependencies for

### Deployment Dependencies

- A Railway account with a Developer or Hobby plan; the three-service stack with two volumes fits comfortably, but the Server should be placed on a plan with 1 GB or more RAM.
- No external services are required: MongoDB is provisioned by the template, and local file storage is the default. SMTP or a Mailgun account is optional and only needed for automated email notifications; an S3-compatible bucket is optional and only needed if you prefer object storage over the volume.
