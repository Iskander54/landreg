#! /bin/sh
truffle migrate
cp -R build/contracts client/src
cd client
npm run start