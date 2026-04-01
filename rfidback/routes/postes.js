const express = require("express");
const router = express.Router();
const { db } = require("../firebase");
const verifierAdmin = require("../Middleware/verifierAdmin");

const STATUTS_VALIDES = ["available", "reserved", "occupied", "blocked"];

// GET /postes — lister tous les postes
router.get("/", async (req, res) => {
  try {
    const snapshot = await db.ref("postes").once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Aucun poste trouvé." });
    }

    const data = snapshot.val();
    const postes = Object.values(data).sort((a, b) => a.numero - b.numero);

    return res.status(200).json({ total: postes.length, postes });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// PATCH /postes/:floor/:numero/reserver — RÉSERVER un poste
router.patch("/:floor/:numero/reserver", async (req, res) => {
  const { floor, numero } = req.params;
  const { uid, prenom } = req.body;

  if (!uid || !prenom) {
    return res.status(400).json({ message: "uid et prenom sont obligatoires." });
  }

  try {
    const userSnap = await db.ref(`autorized/${uid}`).once("value");
    if (!userSnap.exists() || !userSnap.val().autorise) {
      return res.status(403).json({ message: "Utilisateur non autorisé." });
    }

    const posteRef = db.ref(`postes/${floor}/${numero}`);
    const posteSnap = await posteRef.once("value");

    if (!posteSnap.exists()) {
      return res.status(404).json({ message: `Poste ${numero} introuvable.` });
    }

    const poste = posteSnap.val();

    if (poste.statut === "blocked") {
      return res.status(403).json({ message: "Ce poste est bloqué." });
    }
    if (poste.statut === "reserved") {
      return res.status(409).json({ message: "Ce poste est déjà réservé." });
    }
    if (poste.statut === "occupied") {
      return res.status(409).json({ message: "Ce poste est occupé." });
    }

    await posteRef.update({
      statut: "reserved",
      reservePar: uid,
      prenom: prenom,
      dateReservation: new Date().toISOString(),
    });

    return res.status(200).json({
      message: `Poste ${numero} réservé avec succès.`,
      statut: "reserved"
    });

  } catch (error) {
    return res.status(500).json({ message: "Erreur réservation.", error: error.message });
  }
});

// GET /postes/:etage — Récupérer les postes d'un étage
router.get("/:etage", async (req, res) => {
  const etage = decodeURIComponent(req.params.etage);

  try {
    const snapshot = await db.ref(`postes/${etage}`).once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Aucun poste trouvé pour cet étage." });
    }

    const data = snapshot.val();
    const postes = [];

    for (const id in data) {
      postes.push({
        id,
        ...data[id]
      });
    }

    postes.sort((a, b) => a.numero.localeCompare(b.numero));

    return res.status(200).json({ postes });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// PATCH /postes/:floor/:numero/liberer — libérer un poste
router.patch("/:floor/:numero/liberer", async (req, res) => {
  const { floor, numero } = req.params;
  const { uid } = req.body;

  if (!uid) {
    return res.status(400).json({ message: "uid est obligatoire." });
  }

  try {
    const posteRef = db.ref(`postes/${floor}/${numero}`);
    const posteSnap = await posteRef.once("value");

    if (!posteSnap.exists()) {
      return res.status(404).json({ message: "Poste introuvable." });
    }

    const poste = posteSnap.val();

    if (poste.statut === "available") {
      return res.status(400).json({ message: "Ce poste est déjà libre." });
    }
    if (poste.statut === "blocked") {
      return res.status(403).json({ message: "Ce poste est bloqué." });
    }

    const userSnap = await db.ref(`autorized/${uid}`).once("value");
    if (!userSnap.exists()) {
      return res.status(403).json({ message: "Utilisateur introuvable." });
    }

    const user = userSnap.val();
    const estProprietaire = poste.reservePar === uid;
    const estAdmin = user.role === "admin";

    if (!estProprietaire && !estAdmin) {
      return res.status(403).json({ message: "Vous ne pouvez libérer que votre propre poste." });
    }

    await posteRef.update({
      statut: "available",
      reservePar: null,
      prenom: null,
      dateReservation: null,
    });

    return res.status(200).json({ message: "Poste libéré avec succès." });

  } catch (error) {
    return res.status(500).json({ message: "Erreur libération.", error: error.message });
  }
});

// PATCH /postes/:id/statut — changer le statut (admin)
router.patch("/:id/statut", verifierAdmin, async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;

  if (!statut || !STATUTS_VALIDES.includes(statut)) {
    return res.status(400).json({ message: `Statut invalide.` });
  }

  try {
    const posteSnap = await db.ref(`postes/${id}`).once("value");
    if (!posteSnap.exists()) {
      return res.status(404).json({ message: "Poste introuvable." });
    }

    const updates = { statut };

    if (statut === "available") {
      updates.reservePar = null;
      updates.prenom = null;
      updates.dateReservation = null;
    }

    await db.ref(`postes/${id}`).update(updates);
    return res.status(200).json({ message: "Statut mis à jour." });

  } catch (error) {
    return res.status(500).json({ message: "Erreur mise à jour.", error: error.message });
  }
});

// POST /postes — créer un poste (admin)
router.post("/", verifierAdmin, async (req, res) => {
  const { numero, statut } = req.body;

  if (!numero) {
    return res.status(400).json({ message: "Le numéro du poste est obligatoire." });
  }

  const statutInitial = statut || "available";
  if (!STATUTS_VALIDES.includes(statutInitial)) {
    return res.status(400).json({ message: `Statut invalide.` });
  }

  try {
    const existing = await db.ref(`postes/${numero}`).once("value");
    if (existing.exists()) {
      return res.status(409).json({ message: `Le poste ${numero} existe déjà.` });
    }

    await db.ref(`postes/${numero}`).set({
      numero,
      statut: statutInitial,
      reservePar: null,
      prenom: null,
      dateReservation: null,
    });

    return res.status(201).json({ message: `Poste ${numero} créé.` });

  } catch (error) {
    return res.status(500).json({ message: "Erreur création.", error: error.message });
  }
});

// GET /postes/:id — détail d'un poste
router.get("/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const snapshot = await db.ref(`postes/${id}`).once("value");
    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Poste introuvable." });
    }
    return res.status(200).json(snapshot.val());

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// DELETE /postes/:id — supprimer un poste (admin)
router.delete("/:id", verifierAdmin, async (req, res) => {
  const { id } = req.params;

  try {
    const posteSnap = await db.ref(`postes/${id}`).once("value");
    if (!posteSnap.exists()) {
      return res.status(404).json({ message: "Poste introuvable." });
    }

    await db.ref(`postes/${id}`).remove();
    return res.status(200).json({ message: "Poste supprimé." });

  } catch (error) {
    return res.status(500).json({ message: "Erreur suppression.", error: error.message });
  }
});

module.exports = router;