FROM node:10.17.0
LABEL MAINTAINER "Alex-Kevin LOEMBE"

ENV HOST "ganache-cli"
ENV PORT "8545"
ENV NETWORKID "*"

COPY . .
RUN npm install -g truffle serve
RUN npm ci && cd client && npm ci
CMD truffle migrate --network production && \
    cp -R build/contracts client/src && \
    cd client && \
    npm run build && \
    serve -s build -l 3001