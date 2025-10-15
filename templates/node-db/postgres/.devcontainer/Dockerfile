FROM node:22-alpine3.19
WORKDIR /workspace
RUN apk add --no-cache bash git postgresql-client \
    libpq psql # Add libpq and psql for full PostgreSQL CLI and library support
RUN mkdir -p /workspace && chown -R node:node /workspace
USER node
EXPOSE 3000
CMD ["sleep", "infinity"]