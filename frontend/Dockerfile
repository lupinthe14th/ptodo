FROM node:lts-stretch-slim AS base-env
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install vue@next \
  ; \
  yarn global add @vue/cli
RUN yarn
COPY . .

FROM node:lts-stretch-slim AS build-env
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM lkwg82/h2o-http2-server AS production-env
COPY --from=build-env /usr/src/app/dist /var/www/html
