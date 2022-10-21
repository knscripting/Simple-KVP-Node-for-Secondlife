const express = require('express');
const Model = require('../models/model');
const router = express.Router();

router.get('/', function(req, res){
    res.json({status: "online", message: "mmkvp ready" })
})

router.put('/update', async (req, res) => {
    try {
        const id = {mmKey: req.body.mmKey.toString()};
        const updatedData = {mmKey: req.body.mmKey, mmValue: req.body.mmValue};
        const options = { returnDocument: "after" };

        const result = await Model.findOneAndUpdate(
            id, updatedData, options
        )
        res.send(result);
        //console.log('query: ' + query +'update attempt: '+ updatedData.toString());
    }
    catch (error) {
        res.status(500).json({ status: "ERROR", message: error.message })
    }
})

//Post Method
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
        console.log(id);
        const data = await Model.findOne(id);
        res.json(data)
    }
    catch (error) {
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

