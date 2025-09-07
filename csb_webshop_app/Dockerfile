# Multi-stage Dockerfile for Flutter Web app served via Nginx

FROM debian:bookworm-slim AS flutter-sdk
ARG FLUTTER_VERSION=3.24.5
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates curl unzip xz-utils && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/flutter/flutter.git /opt/flutter && cd /opt/flutter && git checkout ${FLUTTER_VERSION}
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter config --enable-web && flutter --version

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .

# Build with env vars passed at build-time if needed
# Example: --build-arg API_BASE_URL=http://localhost:8080
ARG API_BASE_URL=https://api.example.com
ARG STRIPE_PUBLISHABLE_KEY=
ARG FLAVOR=prod
ARG ENABLE_LOGGING=false

RUN flutter build web --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY \
    --dart-define=FLAVOR=$FLAVOR \
    --dart-define=ENABLE_LOGGING=$ENABLE_LOGGING

FROM nginx:1.27-alpine AS runtime
COPY --from=flutter-sdk /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK CMD wget -qO- http://localhost/ | grep -q "<!DOCTYPE html>" || exit 1

