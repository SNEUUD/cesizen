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

app.get("/rapports", (req, res) => {
  const sql = "SELECT * FROM Rapports ORDER BY dateRapport DESC";

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des ressources :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.status(200).json(results);
  });
});

app.get("/rapports_user", (req, res) => {
  const userId = req.query.userId;

  if (!userId) {
    return res.status(400).json({ error: "Paramètre userId requis" });
  }

  const sql = `
    SELECT * FROM Rapports 
    WHERE userRapport = ? 
    ORDER BY dateRapport DESC
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des rapports :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.status(200).json(results);
  });
});

app.post("/add_rapports", (req, res) => {
  const { titreRapport, messageRapport, userRapport, emotionRapport } =
    req.body;

  if (!titreRapport || !messageRapport || !userRapport || !emotionRapport) {
    return res.status(400).json({ error: "Champs requis manquants" });
  }

  const sql = `
    INSERT INTO Rapports (titreRapport, messageRapport, userRapport, emotionRapport, dateRapport)
    VALUES (?, ?, ?, ?, NOW())
  `;

  db.query(
    sql,
    [titreRapport, messageRapport, userRapport, emotionRapport],
    (err, result) => {
      if (err) {
        console.error("Erreur lors de l'ajout du rapport :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      res.status(201).json({ message: "Rapport ajouté avec succès !" });
    }
  );
});

app.get("/emotions", (req, res) => {
  const sql = "SELECT * FROM Emotions ORDER BY IntituleEmotion ASC";

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des émotions :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }
    res.status(200).json(results);
  });
});

app.put("/edit_rapports/:id", (req, res) => {
  const rapportId = req.params.id;
  const { titreRapport, messageRapport, emotionRapport } = req.body;

  if (!titreRapport || !messageRapport || !emotionRapport) {
    return res.status(400).json({ error: "Champs manquants" });
  }

  const sql = `
    UPDATE Rapports
    SET titreRapport = ?, messageRapport = ?, emotionRapport = ?
    WHERE idRapport = ?
  `;

  db.query(
    sql,
    [titreRapport, messageRapport, emotionRapport, rapportId],
    (err, result) => {
      if (err) {
        console.error("Erreur lors de la modification du rapport :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: "Rapport non trouvé" });
      }
      res.status(200).json({ message: "Rapport modifié avec succès !" });
    }
  );
});

app.delete("/delete_rapports/:id", (req, res) => {
  const rapportId = req.params.id;

  if (!rapportId) {
    return res.status(400).json({ error: "Paramètre id requis" });
  }

  const sql = "DELETE FROM Rapports WHERE idRapport = ?";

  db.query(sql, [rapportId], (err, result) => {
    if (err) {
      console.error("Erreur lors de la suppression du rapport :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Rapport non trouvé" });
    }
    res.status(200).json({ message: "Rapport supprimé avec succès !" });
  });
});

app.get("/user/:id", (req, res) => {
  const userId = req.params.id;

  const sql = `SELECT * FROM Utilisateurs WHERE idUtilisateur = ?`;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération de l'utilisateur :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: "Utilisateur non trouvé" });
    }

    const u = results[0];
    res.status(200).json({
      id: u.idUtilisateur,
      nom: u.nomUtilisateur,
      prénom: u.prénomUtilisateur,
      email: u.emailUtilisateur,
      pseudo: u.pseudoUtilisateur,
      sexe: u.sexeUtilisateur,
      // dateNaissance: u.dateNaissanceUtilisateur,  <-- supprimé
      motDePasse: u.motDePasseUtilisateur,
    });
  });
});

// PUT /user/:id
app.put("/user/:id", (req, res) => {
  const userId = req.params.id;
  const { nom, prénom, email, pseudo, sexe, motDePasse } = req.body;

  if (
    !nom ||
    !prénom ||
    !email ||
    !pseudo ||
    !sexe ||
    // !dateNaissance ||  <-- supprimé
    !motDePasse
  ) {
    return res.status(400).json({ error: "Champs requis manquants" });
  }

  const sql = `
    UPDATE Utilisateurs
    SET nomUtilisateur = ?, prénomUtilisateur = ?, emailUtilisateur = ?, pseudoUtilisateur = ?, sexeUtilisateur = ?, motDePasseUtilisateur = ?
    WHERE idUtilisateur = ?
  `;

  db.query(
    sql,
    [nom, prénom, email, pseudo, sexe, motDePasse, userId],
    (err, result) => {
      if (err) {
        console.error("Erreur lors de la mise à jour de l'utilisateur :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: "Utilisateur non trouvé" });
      }
      res.status(200).json({ message: "Utilisateur mis à jour avec succès !" });
    }
  );
});

app.post("/add_ressource", (req, res) => {
  const {
    titreRessource,
    descriptionRessource,
    dateRessource,
    imageRessource,
  } = req.body;

  if (!titreRessource || !descriptionRessource || !dateRessource) {
    return res.status(400).json({ error: "Champs requis manquants" });
  }

  let sql, params;
  if (imageRessource) {
    sql = `
      INSERT INTO Ressources (titreRessource, descriptionRessource, dateRessource, imageRessource)
      VALUES (?, ?, ?, ?)
    `;
    params = [
      titreRessource,
      descriptionRessource,
      dateRessource,
      Buffer.from(imageRessource, "base64"),
    ];
  } else {
    sql = `
      INSERT INTO Ressources (titreRessource, descriptionRessource, dateRessource)
      VALUES (?, ?, ?)
    `;
    params = [titreRessource, descriptionRessource, dateRessource];
  }

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error("Erreur lors de l'ajout de la ressource :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }
    res.status(201).json({ message: "Ressource ajoutée avec succès !" });
  });
});

app.delete("/ressources/:id", (req, res) => {
  const id = req.params.id;
  const sql = "DELETE FROM Ressources WHERE idRessource = ?";
  db.query(sql, [id], (err, result) => {
    if (err) {
      console.error("Erreur suppression ressource :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }
    res.status(200).json({ message: "Ressource supprimée" });
  });
});

app.put("/ressources/:id", (req, res) => {
  const id = req.params.id;
  const { titreRessource, descriptionRessource, imageRessource } = req.body;

  let sql, params;
  if (imageRessource !== undefined) {
    sql =
      "UPDATE Ressources SET titreRessource = ?, descriptionRessource = ?, imageRessource = ? WHERE idRessource = ?";
    params = [
      titreRessource,
      descriptionRessource,
      imageRessource ? Buffer.from(imageRessource, "base64") : null,
      id,
    ];
  } else {
    sql =
      "UPDATE Ressources SET titreRessource = ?, descriptionRessource = ? WHERE idRessource = ?";
    params = [titreRessource, descriptionRessource, id];
  }

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error("Erreur lors de la modification de la ressource :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }
    res.status(200).json({ message: "Ressource modifiée avec succès !" });
  });
});

app.get("/users", (req, res) => {
  const sql = `
    SELECT 
      idUtilisateur AS idUser,
      pseudoUtilisateur AS pseudo,
      emailUtilisateur AS email,
      Roles_idRole AS role
    FROM Utilisateurs
    ORDER BY pseudoUtilisateur ASC
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des utilisateurs :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }
    res.status(200).json(results);
  });
});

const PORT = process.env.PORT || 3050;

app.listen(PORT, () => {
  console.log(`Serveur Node.js démarré sur http://localhost:${PORT}`);
});
