require('dotenv').config();
const cors = require('cors');
const express = require('express') ;
const mongoose = require('mongoose') ;
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
app.use(bodyParser.urlencoded({extended: false}));

const routes = require('./routes/routes');

app.use('/mmkvp', routes)

app.listen(mmKvpPort, () => {
    console.log('mmKVP Node listening on port: ' + mmKvpPort)
})
