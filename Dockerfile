FROM node:lts-alpine

RUN mkdir /app
ADD . /app/

WORKDIR /app
EXPOSE 8000

CMD ["nodejs", "server.js"]
