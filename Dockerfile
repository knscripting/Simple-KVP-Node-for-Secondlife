FROM node:alpine

WORKDIR /usr/src/app

RUN ls -al

ADD package*.json /usr/src/app/

RUN npm install

RUN npm install mongoose nodemon dotenv cors bcrypt --save

RUN npm install nodemon -g

ADD . /usr/src/app/

EXPOSE 8080

CMD ["npm", "start"]
