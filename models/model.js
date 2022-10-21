const mongoose = require('mongoose');
const opts = {
    // Make Mongoose use Unix time (seconds since Jan 1, 1970)
    timestamps: { currentTime: () => Math.floor(Date.now() / 1000) },
  };

const dataSchema = new mongoose.Schema({
    mmKey: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    mmValue: {
        type: String,
        required: true
    }
},opts)
//dataSchema.set('timestamps', {currentTime: () => Math.floor(Date.now() / 1000)
//}); // this will add createdAt and updatedAt timestamps

module.exports = mongoose.model('Data', dataSchema) 
