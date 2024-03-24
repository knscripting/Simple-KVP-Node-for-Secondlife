const { application } = require('express');
const express = require('express');
const Model = require('../models/model');
const router = express.Router();

/*
Upsert is enabled, if record doesn't exist, create it
We record the SL header information as it could be 
handy with debugging, and other functions
*/

router.put('/mmWrite', async (req, res) => {
    try {
        const updatedData = {
            mmKey: req.body.mmKey,
            mmValue: req.body.mmValue,
            mmObjectName: req.headers['x-secondlife-object-name'],
            mmObjectKey: req.headers['x-secondlife-object-key'],
            mmOwnerName: req.headers['x-secondlife-owner-name'],
            mmOwnerKey: req.headers['x-secondlife-owner-key'],
            mmLocalPos: req.headers['x-secondlife-local-position'],
            mmRegion: req.headers['x-secondlife-region'] } ;

        const id = {mmKey: req.body.mmKey.toString()};
        const options = { returnDocument: "after", upsert: "true" };
        const result = await Model.findOneAndUpdate(
            id, updatedData, options
        )
        const sendMe = {mmValue: result.mmValue};
        res.send(sendMe);
        console.log("User:",req.headers['x-secondlife-owner-name'], " Writing:", id );
    }
    catch (error) {
        res.status(500).json({ status: "ERROR", message: error.message })
    }
})

//Get by ID Method
router.post('/mmRead', async (req, res) => {
    try {
        var id = {mmKey: req.body.mmKey};
        console.log("User:",req.headers['x-secondlife-owner-name'], " Reading:",id);
        const result = await Model.findOne(id);
        //res.json(data)
        const sendMe = {mmValue: result.mmValue};
        res.send(sendMe);
        //console.log("Writing:", id );
    }
    catch (error) {
        console.log("No Key");
        res.status(500).json({ status: "failed", message: error.message })
    }
})

//Post Method Not needed
router.post('/mmNew', async (req, res) => {
    const data = new Model({
        mmKey: req.body.mmKey,
        mmValue: req.body.mmValue
    })

    try {
        const dataToSave = await data.save();
        res.status(200).json(dataToSave)
    }
    catch (error) {
        res.status(400).json( { status: "ERROR", message: error.message })
    }
})

//Delete by ID Method
router.post('/mmDelete', async (req, res) => {
    try {
        const id = {mmKey: req.body.mmKey.toString()};
        const data = await Model.findOneAndDelete(id)
        res.send(`Document with ${data.mmKey} deleted`)
    }
    catch (error) {
        res.status(400).json({ status: "failed", message: error.message })
    }
})

//mmValue needs to be a valid json
// ex: {"_id":0, "mmKey":1, "mmValue":1}
//mmField is they document key to regex against
//mmRegex string to search for against mmField
//mmPage mmLimit get this page limit return values
//
router.post('/mmRegex', async (req, res) => {
    if (req.body.mmValue) {
        let jsonCheck;
        try {
            jsonCheck=JSON.parse(req.body.mmValue);
        }
        catch (error) {
            res.status(500).json({ status: "failed", message: error.message }) 
            return console.log("ERROR User:",req.headers['x-secondlife-owner-name']," Error invalid json in mmValue" , req.body.mmValue)
        }
    }
    const returnData=JSON.parse(req.body.mmValue)
    const page = parseInt(req.body.mmPage)
    const limit = parseInt(req.body.mmLimit)
    const map = new Map([[ req.body.mmField , new RegExp(req.body.mmRegex,req.body.mmRegexOp)]])
    const rquery = Object.fromEntries(map)

    try {
        const pageData = await Model.aggregate([
            {
              $facet: {
                query: [
                  { $match: rquery,},
                  { $count: "count",},
                ],
        
                docs: [
                  {$match: rquery,},
                  {$project: returnData, },
                  {$skip: ((page -1) *limit),},
                  {$limit: limit,},
                ],
              },
            },
          ])
        console.log("User:",req.headers['x-secondlife-owner-name'], " RegEx: ",rquery);
        //console.log("Ok RegEx: ",rquery );
        res.send(pageData)
    }
    catch (error){
        console.log("User:",req.headers['x-secondlife-owner-name'], "Error RegEx: ",rquery," msg: ", error.message);
        res.status(500).json({ status: "failed", message: error.message })  
    }
})

module.exports = router;

