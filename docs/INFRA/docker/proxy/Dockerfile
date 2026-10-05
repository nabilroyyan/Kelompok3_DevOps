# syntax=docker/dockerfile:1.7
# =============================================================================
# Axon DSS — image reverse proxy + penyaji frontend (nginx)
# Peran: Infrastructure/Platform Engineer.
#
# Image ini melakukan dua hal sekaligus, sesuai keputusan desain:
#   1. Menyajikan hasil build frontend React (static) pada origin yang sama.
#   2. Menjadi satu-satunya pintu masuk publik: terminasi TLS, penerapan
#      kebijakan (GET/HEAD saja, header keamanan, rate limit), dan meneruskan
#      /api ke service php-fpm di jaringan internal.
#
# Prinsip hardening (Tugas 2):
#   - Multi-stage: toolchain Node (termasuk npm cache) tidak ada di image akhir.
#   - Base image alpine dan versinya di-pin.
#   - Proses berjalan sebagai non-root (USER nginx)  -> T-10, Gate 4.
#     Konsekuensinya nginx mendengarkan port 8080/8443 (bukan 80/443) dan
#     dipetakan ke port publik oleh docker-compose.yml.
#
# Build context: folder docs/  (lihat docker-compose.yml -> build.context: ..)
# =============================================================================

# --- Stage 1: build frontend (Vite) ------------------------------------------
FROM node:26-alpine AS web
WORKDIR /build
COPY Dev/axon-devsecops-dss/app/frontend/package.json \
     Dev/axon-devsecops-dss/app/frontend/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY Dev/axon-devsecops-dss/app/frontend/ ./
# URL API dibiarkan relatif ("/api") agar browser memanggil origin yang sama.
# Dampaknya: tidak ada CORS, tidak ada mixed content, dan CSP bisa diperketat.
ARG VITE_API_URL=/api
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

# --- Stage 2: runtime --------------------------------------------------------
FROM nginx:1.27-alpine

COPY INFRA/docker/proxy/nginx.conf /etc/nginx/nginx.conf
COPY --from=web /build/dist/ /usr/share/nginx/html/

# Path yang harus bisa ditulis saat nginx berjalan sebagai non-root.
# (Pada runtime, /var/cache/nginx dan /tmp dipasang tmpfs lewat Compose.)
RUN mkdir -p /var/cache/nginx /var/log/nginx \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /usr/share/nginx/html

# Least privilege (Gate 4 / T-10)
USER nginx

EXPOSE 8080 8443

# ENTRYPOINT ditulis eksplisit (bukan lewat /docker-entrypoint.sh bawaan image)
# agar perilaku start deterministik dan tidak mencoba menulis ke filesystem
# yang read-only.
ENTRYPOINT ["nginx", "-g", "daemon off;"]
