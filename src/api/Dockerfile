FROM node:16-slim as base
WORKDIR /app
COPY package*.json /app/
COPY index.js /app
RUN npm install
EXPOSE 8080

FROM base as production
CMD [ "node", "index.js" ]
