const Knex = require('knex');
const express = require("express");
const app = express();
const apiRouter = express.Router();

const SERVER_HOST = '0.0.0.0';
const SERVER_PORT = 8080;

const pool = Knex({
    client: 'pg',
    connection: {
        host: process.env.DATABASE_HOST,
        ...(process.env.DATABASE_PORT && { port: process.env.DATABASE_PORT }),
        user: process.env.DATABASE_USER,
        password: process.env.DATABASE_PASSWORD,
        database: process.env.DATABASE_NAME,
    }
});

app.use(express.text());

apiRouter.get("/", (request, response) => {
    response.send(`Response from root API`);
});

apiRouter.post("/write", async (request, response) => {
    await pool.insert({ name: request.body }).into("stuff");
    response.send("OK");
});

apiRouter.get("/read", async (request, response) => {
    const results = await pool("stuff");
    response.json(results);
});

app.use('/api', apiRouter);

app.listen(SERVER_PORT, SERVER_HOST, () => {
    console.log(`Listening on ${SERVER_HOST}:${SERVER_PORT}`);
});