FROM node:16-slim
WORKDIR /app
COPY package*.json /app
COPY index.js /app
RUN npm install
CMD [ "node", "index.js" ]
