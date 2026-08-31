FROM node:24-alpine
WORKDIR /app
RUN apk update && apk upgrade --no-cache
RUN apk add --no-cache nmap nmap-scripts curl openssl tzdata whois
ENV TZ=Europe/London
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "server/index.js"]
