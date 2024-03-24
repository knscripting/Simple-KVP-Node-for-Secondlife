#### A Secondlife Key Value Pair DB and API with mongoDB, Node.JS, and Express
Consider this a work in progress

## What's this do?

mmKVP offers a way to store data externally to SL in a Key-Value-Pair API via http calls.

Secondlife has an issue with persistent data storage. Examples would be, configuration settings for a user for a device or you sell. Visitor logs that can accomate thousands and thousands of people. Persistant storage for huds (Hit Points, Gold, etc). Grid-wide waypoints, tournament score cards and leader boards, scavenger hunts. Basically, any sort of information you don't want lost to deleting an object, resetting a script, or making a change to a data structure. 

In-world your .lsl script makes and HTTP call via the mmKVP api script to the external mmKVP node, that node queries a mongoDB database, and your saved data is returned as a string. It's fast, it can handle large data loads, and IMHO is easier to setup and maintain than php, mySQL databases, GoogleSheets data storage, in-world servers, and if your project is larger than your parcel's, Second-lifes experience framework. 

See LSL-Templates-Examples for how the API works in-world. The rest is up to you and where and how you choose to host the node.

## How to get started:

This requires some know how on basic server hosting, firewalls, docker, .lsl scripting, and a little understand on what node.js/express/mongoose is. (It's a javascript type web server that is too smart for its own good...)

Any use in production on the host/node side, requires adjustments to the .env, docker-compose.yml, for connection strings, shared-secrets, and passwords.

Data is stored by a "key" which is some unique string and a "value" which is also a string. This API allows an LSL script to  GET, PUT, POST, DELETE a web query to the database, adding, changing, deleting KVP records. Data is stored in a MongoDB database, advanced querying is done in LSL, more talented coders than I can certainly improve on the API to suit more complicated structures. If you do, please consider sharing back improvements to this basic resorce.

## Notes on hosting:

For development and testing I recommend using the npm method and your system at home. (see recommended tools)
For production I am using Amazon AWS (ec2 free teir) for the node, nginx to handle ssl configured as a reverse proxy, 
the database is mongodb.com free tier. So far my hosting expenses are $Zero. It'll be a while before I have any project that's going to tax these basic systems. I've tested to setup on old junky machines, RaspberriPi (you can't run mongodb 5+ on a rPI, that configuration requires an external mongoDB instance), AWS, virtual machine hosts. Any machine that can handle npm and docker-compose should work. 

Wrapping the node in SSL and setting up nginx reverse proxy is not difficult and I recommend that setup in production.  Porting this node into a serverless structure is in the future. 

*If you have no idea what any of that means, see the FAQ below*

## Installation:

There are a few ways to do this, locally with npm or via docker-compose. I won't go into the installation or
administration of docker, thats for you to figure out. 

## Recommended tools:

-mongoDB Compass: https://www.mongodb.com/try/download/compass To manage your mongoDB

-Postman: https://app.getpostman.com/ to diagnose and test the API

-Mongodb.com for external database hosting of your mongoDB (free up to 512MB of data then pretty cheap after)

-mongodb-tools for the backup,restore,management of a local instance for your hosting os of choice. 

-nginx + certbot and LetsEncrypt: For a reverse proxy load balancer to handle multiple nodes and SSL. Not required to run but good practices all the same.   https://www.sitepoint.com/how-to-use-ssltls-with-node-js/  https://certbot.eff.org/ 

-Amazon AWS EC2 - for hosting the production node on. up to 30G of server, which should be plenty for almost all of you. (also free)

## MongoDB 
Firstly, decide if you will attach to a local mongoDB instance or a remote mongoDB instance. Personally I think the free (limited to 512M) cluster at mongodb.com is the way to go for starters. By default this project assumes you go that path. If you want to run locally set the correct mongoDB connect string in .env, and have a plan to backup and maintain mongoDB.

If you use the docker-compose-localDB.yml mongoDB's data is configured to live under the MongoData/data directory in this repository. You may and should edit the docker-compose.yml file to map the persistant data to a location better suited to your environment. Data recorded in that director "SHOULD" be persistant among many builds. Again, it's up to you to safeguard your data. 

## The node.js app mmkvp
Secondly, we have a few ways we can run the app, via nodemon in a shell, great for development, docker-compose with an "external" (External to this project) mongoDB or a docker-compose with an "interal" dockerized mongoDB. As mentioned above Research the pros/cons of either approach and choose what is best for your data needs and uptime.

## Option Nodemon: 

```
npm init -y
npm install express mongoose nodemon dotenv cors bcrypt --save
npm install nodemon -g
nodemon server.js
```

## Option docker-compose:

-Decide if you will host mongoDB locally via docker-compose, locally via some other install method, or remotely.

-copy docker-comose-remoteDB.yml or docker-compose-localDB.yml to docker-compose.yml 

-copy template.env to .env and uncomment or add the appropriate conenction string for your setup. Examples are given inside of .env for connecting to your mongoDB

-Build the Container/Containers 
```
docker-compose up --build 
```
**or**
```
docker-compose up -d" 
```
-the mmkvp-node will listen on 8080, if you use mongoDB localy it will listen on 27017

-run **docker ps** to verify the containers are running

-run **docker logs mmkvp-node**  or "docker logs mmkvp-mongodb" accordingly.

-Further administration of a docker environment is beyond the scope of this project. 

## FAQ and Notes

Data is transmitted plain text in the body. However, the way SL handles http requests it's unlikely anyone will be able to sniff out your packets save for your home network. You can add cryptography on the client side and store encrypted data in your DB if you are worried. Or you can implement HTTPS into the app directly or via a frontend. 

I accomplish this with an nginx+certbot reverse proxy.

CORS is also enabled in the hosting code to provide a simple Source header check which can further limit the exposer of your API.

# Q: Hosting looks complicated, do it for me?
A: I'll consider it, lets talk. Contact me in-world. 

# Q: What's this #define stuff in your LSL?
A: #defines are lsl-preprocessor macros that get hard-coded into your script at compile time. Basically they are a script memory saving tool. I've tried to follow this guide in my LSL scripts, you should too:  https://github.com/JasXSL/SL-XOBJ/wiki/LSL-Best-Practices

# Q: The API won't compile?
A: Make sure the lsl-preprocessor is enabled. Beyond that contact me.

# Q: If my project has several different "tables" users, objects, scores for example. Do I need Three nodes?** 
 A: One node and db will work just fine, MongoDB is essentially data agnostic by design, you can put any sort of fields in any order without the need to refresh and update older records. mmKVP only really cares about the KEY *mmKey* you create so the API can find the VALUE *mmValue* . In short, your .LSL needs to pay attention to the KEY. And just figure out how you want to handle the returned string for you Value.

# Q: I need a more advanced query, how can I get something like, "The top 10 scores" out of the system?
A: Regex queries are supported. In your POST body you need to specify:
    mmField: The document key you wish to query ex, mmKey
    mmRegex: The regular Expression or string you want to search for ex, FINDME_ (find keys with "FINDME_" in them)
    mmKey: Not really used
    mmValue: Valid JSON of document keys you want returned. ex: {"_id":0, "mmKey":1, "mmValue":1} 
    mmPage: Results are paginated by default, return this page ex, 1
    mmLimit: limit each page to this number of documents ex, 15

    A valid query returns a json Array
    If I want page 1 with limit 1 I would get something like:

    [
    {
        "query": [
            {
                "count": 55
            }
        ],
        "docs": [
            {
                "mmKey": "FINDME_4227996",
                "mmValue": "thisvalue"
            }
        ]
    }
]

From that you'll need to calucate the number of calls to make, pages and limits. 


# Q: Do I have to use a parsed list for mmValue, can I use JSON or some other data type?
A: mmValue is stored as a string. Anything you can store as a string you can use. ParsedList, JSON, base64 strings. Whatever you need.

# Q: Just how large can this scale up to?
A1: Depends on your hosting setup, using two or three dockerized nodes, nginx-reverse proxy round robining, and a clustered mongoDB even at the free tier levels for all... I would be confident in a thousands of users with busy read-writes. 
A1.1: If you use nginx as a frontend besure to read up worker_connections (default is 768) 
A1.2: A single node, single DB should be able to handle 2000-ish read/writes a minute. Default installs all around with no tweaks on Free Tier Amazon EC2 and MongoDB can maintain 160ms response at 32 Writes per second of a string 1024 characters long.
A1.3: With worker_connections at 2048 on Free Tier 1CPU 1Gig servers a loadtest returned:
```
INFO Max time (s):        60
INFO Concurrency level:   8
INFO Agent:               none
INFO
INFO Completed requests:  719
INFO Total errors:        0
INFO Total time:          60.065037943 s
INFO Requests per second: 12
INFO Mean latency:        168.5 ms
INFO
INFO Percentage of the requests served within a certain time
INFO   50%      165 ms
INFO   90%      174 ms
INFO   95%      179 ms
INFO   99%      215 ms
INFO  100%      1173 ms (longest request)
```
A2: Really though, I'm not sure. In my testing I will hit the 25 requests in 20 seconds llHttpRequest before the response time climbed over 22ms. See the Throttles Section here: https://wiki.secondlife.com/wiki/LlHTTPRequest If your project requires agressive read/write/query you'll need to use more in-world data management and use mmKVP for initialization and periodic (once a minute or event driven) backups. Rule of thumb: In-world will always be faster than out-world and most imporantly, you have to manage the calculated throttles mentioned above. Plan your project's read/writes/storage with those in-game limitations in mind.

## Thanks
Special thanks to the initial examples in this repository for getting me started:

https://github.com/JasXSL 

https://github.com/bhanushalimahesh3/node-rest-api-jwt.git

 

