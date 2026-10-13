# syntax=docker/dockerfile:1.4
# Render: New > Web Service > Docker  (repo me sirf pubspec.yaml, lib/main.dart, Dockerfile chahiye)
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter create . --platforms=web && flutter pub get && flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY <<'CONF' /etc/nginx/templates/default.conf.template
server {
  listen ${PORT};
  root /usr/share/nginx/html;
  index index.html;
  server_tokens off;
  add_header X-Content-Type-Options nosniff always;
  add_header X-Frame-Options DENY always;
  add_header Referrer-Policy no-referrer always;
  location / { try_files $uri $uri/ /index.html; }
}
CONF
