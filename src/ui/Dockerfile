FROM node:16.17.1-alpine3.16 as build
WORKDIR /app
COPY . /app
RUN npm ci
RUN npm run build

FROM nginx:1.23.1-alpine
EXPOSE 8080
COPY ./docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html