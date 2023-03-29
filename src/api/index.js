const Knex = require('knex');
const { response } = require("express");
const express = require("express");
const app = express();
const apiRouter = express.Router();

const HOST = '0.0.0.0';
const PORT = 8080;

const createTcpPool = async config => {
    const dbConfig = {
        client: 'pg',
        connection: {
            host: '/cloudsql/burner-1:us-central1:private-instance-fbf81c44',
            // port: 5432,
            user: 'postgres',
            password: 'postgres',
            database: 'jon',
        },
        ...config,
    };
    return Knex(dbConfig);
};

let pool;

(async () => {
    pool = await createTcpPool({});
})();

apiRouter.get("/", async (request, response) => {
    const result = await pool("stuff");
    response.send(`Response from root API: ${result}`);
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