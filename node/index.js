process.title = 'pubsub-app';

const express = require('express');
const app = express();

const server = require('http').createServer(app);
const { Server } = require("socket.io");
const io = new Server(server);
const redis = require("redis");
// const { createClient } = require('redis');


server.listen(3001);

app.use(function (req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', 'http://localhost:3000');

    // Request methods you wish to allow
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');

    // Request headers you wish to allow
    res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');

    // Set to true if you need the website to include cookies in the requests sent
    // to the API (e.g. in case you use sessions)
    res.setHeader('Access-Control-Allow-Credentials', true);

    // Pass to next layer of middleware
    next();
});




// const channel = 'gas';

// subscriber.subscribe(channel, (message, channel) => {
//     // if (error) {
//     //     throw new Error(error);
//     // }
//     console.log('Messsage', message);
//     console.log(`Subscribed to ${channel} channel. Listening for updates on the ${channel} channel...`);
// });
//
// subscriber.on('message', (channel, message) => {
//     console.log(`Received message from ${channel} channel: ${message}`);
// });
const subscriber = redis.createClient();
subscriber.connect();

io.on('connection', (socket) => {
    const subscribe = subscriber.duplicate()
    // await subscribe.connect();
    // const subscribe = client.duplicate();
    // subscribe to redis

    // const subscribe = redis.createClient();
    //subscribe.psubscribe('*');

    //socket.join('some room');
    //subscribe.subscribe('someroom');


    socket.on('room', (room) => {
        subscribe.connect();
        subscribe.subscribe(room, (message, channel) => {
            socket.emit('message', message);
            console.log(message, channel);
        });
    });


    // subscribe.on("message", (channel, message) => {
    //     console.log("from rails to subscriber:", channel, message);
    //     socket.emit('message', message);
    // });

    // relay redis messages to connected socket
    //  subscribe.pSubscribe('message', (message, channel) => {
    //     console.log(message, channel); // 'message', 'channel'
    //     socket.emit('message', message)
    // });
    // subscribe.on("message", ( channel, message) => {
    //     console.log("from rails to subscriber:", channel, message);
    //     socket.emit('message', message)
    // });
    // subscribe.on('message', (channel, message) => {
    //     console.log(`Received message from  channel: ${message}`);
    // });
    // unsubscribe from redis if session disconnects
    socket.on('disconnect', () => {
        console.log("user disconnected");
        subscribe.disconnect();
    });

});

