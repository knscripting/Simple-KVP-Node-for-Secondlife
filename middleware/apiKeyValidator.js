//API Validator

//API Validator
module.exports = {
    apiKeyValidate: function (req, res, next) {
        if (req.body.apiKey != null && process.env.API_KEY == req.body.apiKey){
            if(err) {
                next(err);
            } else {
                const id = {mmKey: req.body.mmKey.toString()};
                console.log("BAD apiKey:", id );
                res.status(400).json( { status: "ERROR", message: "API Invalid" })
            }
        }
    }
}

/*
const apiKeyValidate =function (req, res, next) {
    if (process.env.API_KEY == req.body.apiKey){
        //console.log("apiKey pass")
        next()
    } else {
        //console.log("apiKey fail")
        const id = {mmKey: req.body.mmKey.toString()};
        console.log("BAD apiKey:", id );
        res.status(400).json( { status: "ERROR", message: "API Invalid" })
    }
}
*/