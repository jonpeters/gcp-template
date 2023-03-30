FROM node:16-slim as base
WORKDIR /app
COPY *.json /app/
COPY ./src/ /app/
RUN npm install
EXPOSE 8080

FROM base as production
CMD [ "node", "src/index.js" ]
