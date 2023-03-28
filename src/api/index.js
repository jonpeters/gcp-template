const { response } = require("express");
const express = require("express");
const app = express();
const apiRouter = express.Router();

const HOST = '0.0.0.0';
const PORT = 8080;

apiRouter.get("/", (request, response) => {
    response.send("Response from root API");
});

apiRouter.get("/json", (request, response) => {
    response.setHeader('content-type', 'application/json');
    response.json({
        "user": "Jon",
        "country": "USA"
    });
});

app.use('/api', apiRouter);

app.listen(PORT, HOST, () => {
    console.log(`Listening on ${HOST}:${PORT}`);
});