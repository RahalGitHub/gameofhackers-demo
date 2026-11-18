
const http = require("node:http");

const serveur = http.createServer((req, res) => {
  res.writeHead(200, {
    "Content-Type": "text/plain; charset=utf-8"
  });

  res.end("Hello World depuis Node.js !");
});

serveur.listen(3000, () => {
  console.log("Serveur démarré sur le port 3000");
});

