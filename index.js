require('dotenv').config();
const cors = require('cors');
const express = require('express') ;
const mongoose = require('mongoose') ;
const aggregatePaginate = require("mongoose-aggregate-paginate-v2");
const bodyParser = require('body-parser');
const mongoString = process.env.DATABASE_URL;
const mmKvpPort = process.env.PORT;

mongoose.connect(mongoString);
const database = mongoose.connection;

database.on('error', (error) => {
    console.log(error)
})

database.once('conencted', () => {
    console.log('Database Connected');
})

const app = express();
app.use(cors())
app.use(express.json());
app.use(express.urlencoded({extended: true}));

//API Validator
const apiKeyValidate =function (req, res, next) {
    if (req.body.apiKey == null){
        res.status(400).json( { status: "ERROR", message: "Bad Request" })
    } else {
        if(process.env.API_KEY == req.body.apiKey){
        //console.log("apiKey pass")
        next()
        } else {
            //console.log("apiKey fail")
            const id = {mmKey: req.body.mmKey.toString()};
            console.log("BAD apiKey:", id );
            res.status(401).json( { status: "ERROR", message: "Auth Invalid" })
        }
    }
}

//app.use(apiKeyValidate)

const routes = require('./routes/routes');

app.get('/', function(req, res){
    res.status(200).send("Ok");
    });
    
app.use('/mmkvp', apiKeyValidate, routes)

app.listen(mmKvpPort, () => {
    console.log('mmKVP Node listening on port: ' + mmKvpPort)
})
