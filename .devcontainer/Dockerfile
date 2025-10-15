FROM node:22-alpine3.19
WORKDIR /workspace
RUN apk add --no-cache bash git
RUN mkdir -p /workspace && chown -R node:node /workspace
USER node
EXPOSE 3000
CMD ["sleep", "infinity"]