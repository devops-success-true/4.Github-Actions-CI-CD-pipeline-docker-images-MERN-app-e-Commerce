# 1. Build stage
FROM node:20-alpine AS build
WORKDIR /app

# copy package manifests
COPY frontend/package*.json ./
RUN npm install --legacy-peer-deps

# build-time arg for React
ARG REACT_APP_API_URL=/api
ENV REACT_APP_API_URL=${REACT_APP_API_URL}

# copy frontend source and build
COPY frontend/ .
RUN npm run build

# 2. Nginx runtime stage
FROM nginx:1.25-alpine
WORKDIR /usr/share/nginx/html

# replace default nginx site
RUN rm -rf /etc/nginx/conf.d/*

# 👇 now copying from root ./nginx/ folder
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# copy built files
COPY --from=build /app/build .

EXPOSE 80
HEALTHCHECK CMD wget -qO- http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

