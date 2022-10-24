# A Secondlife Key Value Pair DB and API with mongoDB, Node.JS, and Express
Consider this a work in progress

Any use in production requires adjustments to the .env, docker-compose.yml, for connection strings, shared-secrets, and passwords.

Secondlife offers a Key-Value-Pair internal Database for Sims that enable the "Experience API". Works great while you are on that sim, not good for other projects that require storage beyond data-on-prim, google sheets, or in-world server objects. 

mmKVP offers a way to store data externally to SL in a similar Key-Value-Pair API via http calls.

Data is stored by a "key" which is some unique string and a "value" which is also a string. This API allows an LSL script to  GET, PUT, POST, DELETE a web query to the database, adding, changing, deleting KVP records. Data is stored in a MongoDB database, advanced querying is done in LSL, more talented coders than I can certainly improve on the API to suit more complicated structures. If you do, please consider sharing back improvements to this basic resorce.

See the internal documentation for more details. 

#Installation

There are a few ways to do this, locally with npm or via docker-compose. I won't go into the installation or
administration of docker, thats for you to figure out. 

#Recommended tools:

-mongoDB Compass: https://www.mongodb.com/try/download/compass To manage your mongoDB

-Postman: https://app.getpostman.com/ to diagnose and test the API

-Mongodb.com for external database hosting 

-mongodb-tools for the backup,restore,management of a local instance for your hosting os of choice. 


#MongoDB 
Firstly, decide if you will attach to a local mongoDB instance or a remote mongoDB instance. Personally I think the free (limited to 512M) cluster at mongodb.com is the way to go for starters. By default this project assumes you go that path. If you want to run locally set the correct mongoDB connect string in .env, and have a plan to backup and maintain mongoDB.


If you use the docker-compose-localDB.yml mongoDB's data is configured to live under the MongoData/data directory in this repository. You may and should edit the docker-compose.yml file to map the persistant data to a location better suited to your environment. Data recorded in that director "SHOULD" be persistant among many builds. Again, it's up to you to safeguard your data. 



#The node.js app mmkvp
Secondly, we have a few ways we can run the app, via nodemon in a shell, great for development, docker-compose with an "external" (External to this project) mongoDB or a docker-compose with an "interal" dockerized mongoDB. As mentioned above Research the pros/cons of either approach and choose what is best for your data needs and uptime.

#Option Nodemon: 

npm init -y

npm install express mongoose nodemon dotenv cors bcrypt --save

npm install nodemon -g

nodemon server.js


#Option docker-compose:

-Decide if you will host mongoDB locally via docker-compose, locally via some other install method, or remotely.

-copy docker-comose-remoteDB.yml or docker-compose-localDB.yml to docker-compose.yml 

-copy template.env to .env and uncomment or add the appropriate conenction string for your setup. Examples are given inside of .env for connecting to your mongoDB

-run "docker-compose up --build" or "docker-compose up -d" 

-the mmkvp-node will listen on 8080, if you use mongoDB localy it will listen on 27017

-run "docker ps" to verify the containers are running

-run "docker logs mmkvp-node"  or "docker logs mmkvp-mongodb" accordingly.

-Further administration of a docker environment is beyond the scope of this project. 



#ToDo

-Add LSL example and proof of concept files

-Document

-https?


#Notes

Data is transmitted plain text in the body. However, the way SL handles http requests it's unlikely anyone will be able to sniff out your packets save for your home network. You can add cryptography on the client side and store encrypted data in your DB if you are worried. Or you can implement HTTPS into the app directly or via a frontend. 

Eventually I might do just that for completness sake. 


#Thanks
Special thanks to the initial examples in this repository for getting me started:

https://github.com/bhanushalimahesh3/node-rest-api-jwt.git

 

