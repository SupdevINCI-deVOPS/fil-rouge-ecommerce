FROM node:18-alpine

# Installe Python + outils de compilation pour bcrypt
RUN apk add --no-cache python3 make g++

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

RUN mkdir -p public/uploads/shop public/uploads/product public/uploads/user

EXPOSE 3000

CMD ["node", "./bin/www"]