const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
require("dotenv").config();
const { v4: uuidv4 } = require("uuid");

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

db.connect((err) => {
  if (err) {
    console.error("Erreur de connexion à la base de données :", err);
  } else {
    console.log("Connecté à la base de données MySQL !");
  }
});

app.get("/", (req, res) => {
  res.send("Backend Node.js OK");
});

app.post("/login", (req, res) => {
  const { emailUtilisateur, motDePasseUtilisateur } = req.body;

  const sql = `
    SELECT * FROM Utilisateurs
    WHERE emailUtilisateur = ? AND motDePasseUtilisateur = ?
  `;

  db.query(sql, [emailUtilisateur, motDePasseUtilisateur], (err, results) => {
    if (err) {
      console.error("Erreur lors de la connexion :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: "Email ou mot de passe incorrect" });
    }

    const utilisateur = results[0];
    res.status(200).json({
      message: "Connexion réussie",
      utilisateur: {
        id: utilisateur.idUtilisateur,
        nom: utilisateur.nomUtilisateur,
        prénom: utilisateur.prénomUtilisateur,
        email: utilisateur.emailUtilisateur,
        pseudo: utilisateur.pseudoUtilisateur,
        role: utilisateur.Roles_idRole,
      },
    });
  });
});

app.post("/register", (req, res) => {
  const {
    nomUtilisateur,
    prénomUtilisateur,
    emailUtilisateur,
    pseudoUtilisateur,
    sexeUtilisateur,
    dateNaissanceUtilisateur,
    motDePasseUtilisateur,
  } = req.body;

  if (
    !nomUtilisateur ||
    !prénomUtilisateur ||
    !emailUtilisateur ||
    !pseudoUtilisateur ||
    !motDePasseUtilisateur
  ) {
    return res.status(400).json({ error: "Champs requis manquants" });
  }

  const sql = `
    INSERT INTO Utilisateurs 
    (idUtilisateur, nomUtilisateur, prénomUtilisateur, emailUtilisateur, pseudoUtilisateur, sexeUtilisateur, dateNaissanceUtilisateur, motDePasseUtilisateur, Roles_idRole, statusUtilisateur)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const id = uuidv4();
  const roleParDéfaut = 1;
  const statutParDéfaut = "activé";

  db.query(
    sql,
    [
      id,
      nomUtilisateur,
      prénomUtilisateur,
      emailUtilisateur,
      pseudoUtilisateur,
      sexeUtilisateur,
      dateNaissanceUtilisateur,
      motDePasseUtilisateur,
      roleParDéfaut,
      statutParDéfaut,
    ],
    (err, result) => {
      if (err) {
        console.error("Erreur lors de l'inscription :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }

      res.status(201).json({ message: "Inscription réussie !" });
    }
  );
});

app.get("/ressources", (req, res) => {
  const sql = "SELECT * FROM Ressources ORDER BY dateRessource DESC";

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des ressources :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    // Convertir le buffer MEDIUMBLOB en chaîne base64
    const ressources = results.map((ressource) => {
      if (ressource.imageRessource) {
        // ressource.imageRessource est un Buffer, on le convertit en base64 string
        ressource.imageRessource = ressource.imageRessource.toString("base64");
      }
      return ressource;
    });

    res.status(200).json(ressources);
  });
});


const PORT = process.env.PORT || 3050;

app.listen(PORT, () => {
  console.log(`Serveur Node.js démarré sur http://localhost:${PORT}`);
});
