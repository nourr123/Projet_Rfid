const express = require("express");
const router = express.Router();
const { db } = require("../firebase");
const verifierAdmin = require("../Middleware/verifierAdmin");

// GET /utilisateurs — lister TOUS les utilisateurs
router.get("/", async (req, res) => {
  try {
    const snapshot = await db.ref("autorized").once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Aucun utilisateur trouvé." });
    }

    const data = snapshot.val();
    const utilisateurs = [];

    for (const uid in data) {
      const u = data[uid];
      utilisateurs.push({
        uid: u.uid,
        email: u.email,
        prenom: u.prenom || "",
        nom: u.nom || "",
        nomComplet: `${u.prenom || ""} ${u.nom || ""}`.trim(),
        role: u.role,
        autorise: u.autorise,
      });
    }

    return res.status(200).json({ total: utilisateurs.length, utilisateurs });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// GET /utilisateurs/:uid — obtenir un utilisateur
router.get("/:uid", async (req, res) => {
  const { uid } = req.params;

  try {
    const snapshot = await db.ref(`autorized/${uid}`).once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Utilisateur introuvable." });
    }

    const u = snapshot.val();

    return res.status(200).json({
      uid: u.uid,
      email: u.email,
      prenom: u.prenom || "",
      nom: u.nom || "",
      nomComplet: `${u.prenom || ""} ${u.nom || ""}`.trim(),
      role: u.role,
      autorise: u.autorise,
    });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// POST /utilisateurs — créer un utilisateur
router.post("/", verifierAdmin, async (req, res) => {
  const { uid, email, password, prenom, nom, role } = req.body;

  if (!uid || !email || !password || !prenom || !nom || !role) {
    return res.status(400).json({
      message: "Champs manquants : uid, email, password, prenom, nom, role sont obligatoires.",
    });
  }

  if (!["admin", "employee"].includes(role)) {
    return res.status(400).json({
      message: "Rôle invalide. Valeurs acceptées : admin, employee.",
    });
  }

  try {
    const existing = await db.ref(`autorized/${uid}`).once("value");
    if (existing.exists()) {
      return res.status(409).json({ message: "Un utilisateur avec cet UID existe déjà." });
    }

    await db.ref(`autorized/${uid}`).set({
      uid,
      email,
      password,
      prenom,
      nom,
      role,
      autorise: true,
    });

    return res.status(201).json({
      message: "Utilisateur créé avec succès.",
      uid
    });

  } catch (error) {
    return res.status(500).json({
      message: "Erreur création.",
      error: error.message
    });
  }
});

// PUT /utilisateurs/:uid — modifier un utilisateur
router.put("/:uid", verifierAdmin, async (req, res) => {
  const { uid } = req.params;
  const { email, password, prenom, nom, role, autorise } = req.body;

  try {
    const snapshot = await db.ref(`autorized/${uid}`).once("value");
    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Utilisateur introuvable." });
    }

    const updates = {};
    if (email !== undefined) updates.email = email;
    if (prenom !== undefined) updates.prenom = prenom;
    if (nom !== undefined) updates.nom = nom;
    if (autorise !== undefined) updates.autorise = autorise;
    if (password !== undefined && password !== "") updates.password = password;
    if (role !== undefined) {
      if (!["admin", "employee"].includes(role)) {
        return res.status(400).json({
          message: "Rôle invalide. Valeurs acceptées : admin, employee.",
        });
      }
      updates.role = role;
    }

    await db.ref(`autorized/${uid}`).update(updates);

    return res.status(200).json({
      message: "Utilisateur modifié avec succès.",
      uid,
      modifications: Object.keys(updates),
    });

  } catch (error) {
    return res.status(500).json({
      message: "Erreur modification.",
      error: error.message
    });
  }
});

// DELETE /utilisateurs/:uid — supprimer un utilisateur
router.delete("/:uid", verifierAdmin, async (req, res) => {
  const { uid } = req.params;

  try {
    const snapshot = await db.ref(`autorized/${uid}`).once("value");
    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Utilisateur introuvable." });
    }

    if (uid === req.admin.uid) {
      return res.status(400).json({
        message: "Un admin ne peut pas se supprimer lui-même.",
      });
    }

    await db.ref(`autorized/${uid}`).remove();

    return res.status(200).json({
      message: "Utilisateur supprimé avec succès.",
      uid
    });

  } catch (error) {
    return res.status(500).json({
      message: "Erreur suppression.",
      error: error.message
    });
  }
});

module.exports = router;