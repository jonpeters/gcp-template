FROM node:16.17.1-alpine3.16 as base
WORKDIR /app
COPY . /app
RUN npm ci

FROM base as development
ENV NODE_ENV development
EXPOSE 3000
CMD [ "npm", "start" ]

FROM base as production
RUN npm run build

FROM nginx:1.23.1-alpine
EXPOSE 8080
COPY ./docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --from=production /app/build /usr/share/nginx/html