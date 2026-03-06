# mlops-course-twin — Deploy your Digital Twin (AWS + Bedrock)

A full‑stack “Digital Twin” chatbot built as part of **Ed Donner’s MLOps course** (AI in Production / Week 2). The app consists of:

- **Frontend:** Next.js + React + Tailwind UI chat interface
- **Backend:** FastAPI service that calls **AWS Bedrock** (`bedrock-runtime`) to generate responses
- **Deployment:** AWS Lambda-ready (via **Mangum**) + a helper script to build a Lambda zip package

---

## What’s in here?

### ✨ Features
- Simple chat UI with session memory
- Backend conversation persistence:
  - **Local JSON files** (default)
  - **S3** (optional, toggle via env var)
- AWS Bedrock model selection via `BEDROCK_MODEL_ID`
- Serverless-friendly FastAPI → Lambda adapter (`lambda_handler.py`)

---

## Architecture

### Local development
```text
Browser → Next.js (localhost:3000) → FastAPI (localhost:8000) → AWS Bedrock
```

### AWS deployment (typical)
```text
Browser → Next.js (Vercel/hosting) → API Gateway → Lambda (FastAPI via Mangum) → AWS Bedrock
                                                     ↘ (optional) S3 for memory
```

---

## Repo structure

```text
.
├── backend/
│   ├── server.py            # FastAPI API (Bedrock + memory)
│   ├── lambda_handler.py    # Mangum adapter for AWS Lambda
│   ├── deploy.py            # Builds lambda-deployment.zip via Docker
│   ├── context.py           # Builds the “digital twin” system prompt
│   ├── resources.py         # Loads persona data from ./data/*
│   ├── requirements.txt
│   └── pyproject.toml
└── frontend/
    ├── app/                 # Next.js app router
    ├── components/twin.tsx  # Chat UI + API call
    └── package.json
```

> Note: `backend/data/` is intentionally **not committed** (ignored by `.gitignore`). You’ll create it locally with your persona data.

---

## Prerequisites

- **Python 3.12**
- **Node.js + npm**
- **AWS credentials** available to your environment (local dev and/or Lambda)
- **Access to AWS Bedrock** in your chosen region
- **Docker** (only required to build the Lambda zip via `backend/deploy.py`)

---

## Quickstart (local)

### 1) Backend: install & configure

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # (Windows: .venv\Scripts\activate)
pip install -r requirements.txt
```

Create your local env file:

```bash
# backend/.env
CORS_ORIGINS=http://localhost:3000
DEFAULT_AWS_REGION=eu-central-1
BEDROCK_MODEL_ID=amazon.nova-lite-v1:0

# memory storage
USE_S3=false
MEMORY_DIR=../memory
# if USE_S3=true, also set:
# S3_BUCKET=your-bucket-name
```

### 2) Backend: create persona data files

`backend/resources.py` expects these files:

- `backend/data/facts.json`  ✅ required
- `backend/data/summary.txt` ✅ required
- `backend/data/style.txt`   ✅ required
- `backend/data/linkedin.pdf` (optional)

Create the folder + files:

```bash
mkdir -p backend/data
```

Example minimal `facts.json`:

```json
{
  "full_name": "Your Full Name",
  "name": "Your Name",
  "title": "Your Role",
  "location": "City, Country",
  "highlights": [
    "What you do",
    "What you're known for",
    "What you're looking for"
  ]
}
```

Example `summary.txt`:

```txt
Short bio / background notes you want the twin to use as grounded context.
```

Example `style.txt`:

```txt
How you write/speak (tone, brevity, preferred structure, etc.).
```

> If `linkedin.pdf` is missing, the backend will continue with “LinkedIn profile unavailable”.

### 3) Backend: run the API

From `backend/`:

```bash
python server.py
```

Or with reload:

```bash
uvicorn server:app --reload --host 0.0.0.0 --port 8000
```

Backend runs at: `http://localhost:8000`

---

### 4) Frontend: install & run

```bash
cd frontend
npm install
npm run dev
```

Open: `http://localhost:3000`

#### Important: point the frontend to your backend
Right now, `frontend/components/twin.tsx` calls a hard-coded API Gateway URL:

```ts
fetch('https://tgvm5qb41f.execute-api.eu-central-1.amazonaws.com/chat', ...)
```

For local development, change it to:

```ts
fetch('http://localhost:8000/chat', ...)
```

> Tip: A nice improvement is to refactor this into an env var (e.g. `NEXT_PUBLIC_API_BASE_URL`) so you don’t edit code between environments. (DONE)

---

## API

### `POST /chat`
Send a user message, get back assistant response + `session_id` (used for memory).

**Request**
```json
{
  "message": "Hello!",
  "session_id": "optional-existing-session-id"
}
```

**Response**
```json
{
  "response": "Hi! ...",
  "session_id": "generated-or-provided-session-id"
}
```

### `GET /conversation/{session_id}`
Returns stored conversation history for that session.

### `GET /health`
Basic health info, includes whether S3 memory is enabled and which Bedrock model is in use.

---

## Memory / Storage

By default, the backend stores conversation as JSON files under `MEMORY_DIR` (default `../memory`), with filenames like:

```text
<session_id>.json
```

To use S3 instead:
- Set `USE_S3=true`
- Set `S3_BUCKET=<your bucket>`
- Ensure your IAM role/user can `GetObject`/`PutObject` to that bucket.

---

## Deploy to AWS (Lambda + API Gateway)

### 1) Build the Lambda deployment zip

The repo includes `backend/deploy.py` which:
- installs deps inside a Lambda-compatible Docker image
- copies source files
- (optionally) copies `backend/data/` into the package
- outputs `lambda-deployment.zip`

```bash
cd backend
python deploy.py
# -> lambda-deployment.zip
```

### 2) Create a Lambda function
Typical settings:
- Runtime: **Python 3.12**
- Handler: `lambda_handler.handler`
- Upload `lambda-deployment.zip`
- Configure env vars (same as local `.env`, plus `S3_BUCKET` if using S3)
- Attach IAM permissions for:
  - Bedrock runtime access in your region
  - (Optional) S3 bucket read/write for memory

### 3) Add API Gateway route
Create an API Gateway (HTTP API is a common choice), add:
- `POST /chat` → Lambda integration
- Enable CORS for your frontend origin(s)

### 4) Update the frontend API URL
Replace the URL in `frontend/components/twin.tsx` with your new API endpoint.

---

## Customizing your Digital Twin

The “personality” and grounding context come from `backend/context.py`, which builds a system prompt using:

- `facts.json`
- `summary.txt`
- `style.txt`
- optionally extracted text from `linkedin.pdf`

To create a new twin:
1. Replace the files in `backend/data/`
2. Deploy/restart the backend

---

## Troubleshooting

- **CORS errors in the browser**
  - Ensure backend `CORS_ORIGINS` includes your frontend URL
  - Ensure API Gateway CORS is configured (if deployed)

- **403 / AccessDenied from Bedrock**
  - Your AWS identity (local credentials or Lambda role) likely lacks Bedrock permissions or model access.

- **Backend fails on startup**
  - Make sure `backend/data/facts.json`, `summary.txt`, and `style.txt` exist (they're required).

- **Tailwind v4 "Cannot find native binding" error**
  - See [`tailwind_oxide_error_fix_guide.md`](./tailwind_oxide_error_fix_guide.md) for a complete diagnosis and fix guide.

---

## Credits
- Built for **Ed Donner’s MLOps / AI in Production course** (Week 2: Digital Twin).