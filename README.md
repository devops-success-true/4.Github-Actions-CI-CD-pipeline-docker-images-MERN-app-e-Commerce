# Dockerized MERN Stack E-commerce Application

This repository contains a production-grade Docker Compose setup for deploying a MERN stack e-commerce application.
The Dockerization was built on top of the base source code available here:
➡️ MERN Base Repo: https://github.com/devops-success-true/1.MERN-stack-E-commerce-basecode-for-labs

---

## 🔹 Implementation Overview

- Dockerfiles were created for both the **frontend** and **backend**.
- A custom **nginx.conf** file lives under the dedicated `nginx/` folder.
- Both Dockerfiles use **multi-stage builds**:
  - ✅ Smaller final image sizes
  - ✅ Faster rebuilds after new commits
- **Docker Compose** orchestrates the stack:
  - Containers: `frontend` (Nginx + React static build), `backend` (Node/Express), and a one‑shot `seed` service.
  - The **seed container** runs `npm run seed` to populate MongoDB with initial data (products, users, etc.).
    - Runs **only when explicitly invoked** (not on every deploy).
    - Use it to bootstrap brand‑new environments.
- **Resiliency**:
  - `restart: unless-stopped` ensures containers auto‑restart after crashes or VM reboot.
  - The app comes back online automatically as long as Docker service starts on boot.

---

## 🔹 Project Structure

```
3.-Dockerizing-docker-composing-MERN-stack-E-commerce/
│
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── index.js
│   └── ...
│
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   └── ...
│
├── nginx/
│   └── nginx.conf
│
├── docker-compose.yaml
├── .env
└── README.md
```

---

## 🔹 Environment Variables

Defined in `.env` (exclude this file from Git using `.gitignore`):

```ini
# Mongo Atlas connection
MONGO_URI=mongodb+srv://<user>:<password>@cluster0.mongodb.net/ecommerce

# Frontend origin (host/domain of frontend service)
ORIGIN=http://192.168.1.50   # replace with your VM IP or domain

# Email config (for OTP/reset flows)
EMAIL=youremail@example.com
PASSWORD=yourpassword

# JWT, cookies, OTP
LOGIN_TOKEN_EXPIRATION=30d
OTP_EXPIRATION_TIME=120000
PASSWORD_RESET_TOKEN_EXPIRATION=2m
COOKIE_EXPIRATION_DAYS=30

# Secret key
SECRET_KEY=super_secret_value

# Frontend API base (build-time for React; proxied via Nginx to backend)
REACT_APP_BASE_URL=/api
```

> Notes
> - `ORIGIN` is used by the backend for CORS (what browser origins are allowed).
> - `REACT_APP_BASE_URL` is baked into the frontend build (e.g., `/api`), and Nginx proxies `/api` → `backend:8000` inside the Docker network.

---

## 🔹 Key Commands

**Build & Start Services**
```bash
docker compose up -d --build
```

**Stop & Remove Containers**
```bash
docker compose down
```

**View Logs**
```bash
docker compose logs -f
```

**Rebuild Only Frontend**
```bash
docker compose build frontend
docker compose up -d frontend
```

**Run Database Seeder (one-shot)**
```bash
docker compose run --rm seed
```

**Full Clean (containers, images, anonymous volumes, orphans)**
```bash
docker compose down -v --rmi all --remove-orphans
```

---

## 🔹 Nginx Configuration

You can use either the **simplified** config (most common) or the **production-grade** config (adds gzip, caching, headers, timeouts). Both assume Compose service name `backend` on port `8000`.

### Option A — Simplified (most common)
Create `nginx/nginx.conf` with:
```nginx
server {
    listen 80;

    # Serve React build
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri /index.html;
    }

    # Proxy API to backend
    location /api/ {
        proxy_pass http://backend:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Option B — Production-grade
Create `nginx/nginx.conf` with:
```nginx
worker_processes  auto;

events {
  worker_connections  1024;
}

http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  # Performance
  sendfile        on;
  tcp_nopush      on;
  tcp_nodelay     on;
  keepalive_timeout  65;

  # Gzip
  gzip on;
  gzip_comp_level 5;
  gzip_min_length 256;
  gzip_proxied any;
  gzip_types
    text/plain text/css application/json application/javascript
    application/x-javascript text/xml application/xml application/xml+rss
    image/svg+xml application/font-woff2 application/vnd.ms-fontobject
    font/ttf font/opentype;

  # WebSocket upgrade map
  map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
  }

  upstream backend_upstream {
    server backend:8000;
    keepalive 32;
  }

  server {
    listen 80;
    server_name _;

    root  /usr/share/nginx/html;
    index index.html;

    # Security headers (baseline)
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header Referrer-Policy no-referrer-when-downgrade always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Cache static assets aggressively (filenames are hash-stamped)
    location ~* \.(?:js|css|png|jpg|jpeg|gif|svg|ico|woff2?|ttf|otf)$ {
      expires 1y;
      add_header Cache-Control "public, max-age=31536000, immutable";
      try_files $uri =404;
      access_log off;
    }

    # Do NOT cache the app shell
    location = /index.html {
      add_header Cache-Control "no-store, max-age=0";
      try_files $uri =404;
    }

    # SPA fallback
    location / {
      try_files $uri /index.html;
    }

    # API proxy
    location /api/ {
      proxy_pass http://backend_upstream;
      proxy_http_version 1.1;

      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;

      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;

      proxy_connect_timeout 5s;
      proxy_read_timeout 60s;
      client_max_body_size 10m;
    }

    # Health
    location = /healthz {
      return 200 "ok\n";
      add_header Content-Type text/plain;
      access_log off;
    }
  }
}
```

---

## 🔹 Access

- Frontend: `http://<VM-IP-or-domain>/`
- API (via Nginx proxy): `http://<VM-IP-or-domain>/api/...`

---

## 🔹 Production Notes

- Containers are **stateless**; persistent data lives in **MongoDB Atlas**.
- `restart: unless-stopped` brings services back after VM reboot.

---

## 🔹 Seeder Lifecycle (when it runs)

- Seeding is **not** part of the normal app startup.
- You run it **manually** when bootstrapping a **new environment**:
  ```bash
  docker compose run --rm seed
  ```
- The container exits when it’s done. No persistent runtime impact.

---

## 🔹 Troubleshooting (quick hits)

- **Frontend builds but API 404s** → Check `nginx/nginx.conf` proxy (`backend:8000`) and that `backend` is healthy.
- **CORS errors in browser** → Ensure `.env` `ORIGIN` matches your site origin (scheme/host/port) and backend reads it.
- **React calling wrong API path** → Verify `REACT_APP_BASE_URL` used at build-time and Nginx proxies that prefix to backend.
- **After reboot nothing is up** → Confirm Docker service is enabled and `restart: unless-stopped` is in compose.

---

That’s it. Straightforward, production-like, and easy to extend (TLS at LB/CDN, add monitoring, or move to K8s).
