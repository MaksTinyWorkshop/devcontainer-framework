FROM node:22-alpine3.19
WORKDIR /workspace
RUN apk add --no-cache bash git mysql-client \
    mariadb-connector-c # Add MariaDB Connector/C for better MySQL compatibility and utilities
RUN mkdir -p /workspace && chown -R node:node /workspace
USER node
EXPOSE 3000
CMD ["sleep", "infinity"]