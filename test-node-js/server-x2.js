
const http = require("node:http");

const serveur = http.createServer((req, res) => {

  // On récupère l'URL demandée
  const url = new URL(req.url, "http://localhost:3000");

  // On récupère le nombre dans l'URL
  const nombre = url.searchParams.get("nombre");

  // On prépare le résultat
  let resultat = "";

  if (nombre !== null && nombre.trim() !== "") {
    const n = Number(nombre);

    if (Number.isFinite(n)) {
      resultat = `<h2>Résultat : ${n * n}</h2>`;
    } else {
      resultat = "<p>Nombre invalide</p>";
    }
  }

  // On envoie une page HTML
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8"
  });

  res.end(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Calculateur</title>
      </head>
      <body>

        <h1>Calculateur de carré</h1>

        <form method="GET">
          <input type="number"
                 name="nombre"
                 step="any"
                 required>

          <button type="submit">
            Mettre au carré
          </button>
        </form>

        ${resultat}

      </body>
    </html>
  `);
});

serveur.listen(3000, () => {
  console.log("Serveur sur http://localhost:3000");
});

