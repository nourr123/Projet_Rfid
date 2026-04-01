const express = require("express");
const router  = express.Router();
const jwt     = require("jsonwebtoken");
const { db }  = require("../firebase");

router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email et mot de passe obligatoires." });
  }

  try {
    const snapshot = await db.ref("autorized").once("value");

    if (!snapshot.exists()) {
      return res.status(401).json({ message: "Email ou mot de passe incorrect." });
    }

    const data = snapshot.val();

    let utilisateurTrouve = null;
    for (const uid in data) {
      if (data[uid].email === email) {
        utilisateurTrouve = data[uid];
        break;
      }
    }

    if (!utilisateurTrouve) {
      return res.status(401).json({ message: "Email ou mot de passe incorrect." });
    }

    if (!utilisateurTrouve.autorise) {
      return res.status(403).json({ message: "Compte désactivé. Contactez l'administrateur." });
    }

    if (password !== utilisateurTrouve.password) {
      return res.status(401).json({ message: "Email ou mot de passe incorrect." });
    }

    const token = jwt.sign(
      {
        uid:   utilisateurTrouve.uid,
        email: utilisateurTrouve.email,
        role:  utilisateurTrouve.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    return res.status(200).json({
      message:    "Connexion réussie.",
      token,
      uid:        utilisateurTrouve.uid,
      role:       utilisateurTrouve.role,
      nomComplet: `${utilisateurTrouve.prenom} ${utilisateurTrouve.nom}`,
      expiresIn:  "24h",
    });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

module.exports = router;