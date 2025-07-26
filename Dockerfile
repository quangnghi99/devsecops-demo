# Build stage
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html

# Add nginx configuration if needed
# Run nginx as a non-root user
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

# COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80

# Health check to ensure nginx is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
  CMD curl -f http://localhost/ || exit 1

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]