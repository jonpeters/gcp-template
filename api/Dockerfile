FROM node:16-slim as base
WORKDIR /app
COPY *.json /app/
COPY src /app/src
RUN npm install
EXPOSE 8080

FROM base as production
CMD [ "node", "/app/src/index.js" ]
