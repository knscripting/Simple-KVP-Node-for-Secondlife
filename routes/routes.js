const express = require('express');
const Model = require('../models/model');
const router = express.Router();



router.get('/', function(req, res){
    res.json({status: "online", message: "mmkvp ready" })
})

/*
Upsert is enabled, if record doesn't exist, create it
We record the SL header information as it could be 
handy with debugging, and other functions
*/

router.put('/update', async (req, res) => {
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
        //res.send(result) //working
        const sendMe = {mmValue: result.mmValue};
        res.send(sendMe);
        console.log("Writing:", id);
    }
    catch (error) {
        res.status(500).json({ status: "ERROR", message: error.message })
    }
})

//Post Method Not needed
router.post('/create', async (req, res) => {
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

//Get all Method

router.get('/getAll', async (req, res) => {
    try {
        const data = await Model.find();
        res.json(data)
    }
    catch (error) {
        res.status(500).json({ status: "failed", message: error.message })
    }
})

//Get by ID Method
router.post('/getOne', async (req, res) => {
    try {
        var id = {mmKey: req.body.mmKey};
        console.log("Reading:",id);
        const data = await Model.findOne(id);
        res.json(data)
    }
    catch (error) {
        console.log("No Key");
        res.status(500).json({ status: "failed", message: error.message })
    }
})

//Delete by ID Method
router.post('/delete', async (req, res) => {
    try {
        const id = {mmKey: req.body.mmKey.toString()};
        const data = await Model.findOneAndDelete(id)
        res.send(`Document with ${data.mmKey} has been deleted..`)
    }
    catch (error) {
        res.status(400).json({ status: "failed", message: error.message })
    }
})

module.exports = router;

