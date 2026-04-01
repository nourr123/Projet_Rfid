const express       = require("express");
const router        = express.Router();
const { db }        = require("../firebase");
const verifierAdmin = require("../Middleware/verifierAdmin");

// ─────────────────────────────────────────────
// GET /pointage — tous les pointages (admin)
// ─────────────────────────────────────────────
router.get("/", verifierAdmin, async (req, res) => {
  try {
    const snapshot = await db.ref("pointage").once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Aucun pointage trouvé." });
    }

    const data     = snapshot.val();
    const resultat = [];

    for (const uid in data) {
      const dates = data[uid];
      for (const date in dates) {
        const journee  = dates[date];
        const sessions = [];

        for (const key in journee) {
          if (key.startsWith("session")) {
            sessions.push({
              session: key,
              entree:  journee[key].entree || null,
              sortie:  journee[key].sortie || null,
            });
          }
        }

        resultat.push({
          uid,
          nom:           journee.nom           || null,
          total_travail: journee.total_travail  || null,
          date,
          sessions,
        });
      }
    }

    return res.status(200).json({ total: resultat.length, pointages: resultat });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// ─────────────────────────────────────────────
// GET /pointage/:uid — pointages d'un employé
// ─────────────────────────────────────────────
router.get("/:uid", async (req, res) => {
  const { uid } = req.params;

  try {
    const snapshot = await db.ref(`pointage/${uid}`).once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: "Aucun pointage trouvé pour cet employé." });
    }

    const dates    = snapshot.val();
    const resultat = [];

    for (const date in dates) {
      const journee  = dates[date];
      const sessions = [];

      for (const key in journee) {
        if (key.startsWith("session")) {
          sessions.push({
            session: key,
            entree:  journee[key].entree || null,
            sortie:  journee[key].sortie || null,
          });
        }
      }

      resultat.push({
        date,
        nom:           journee.nom           || null,
        total_travail: journee.total_travail  || null,
        sessions,
      });
    }

    return res.status(200).json({
      uid,
      total_jours: resultat.length,
      pointages:   resultat,
    });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

// ─────────────────────────────────────────────
// GET /pointage/:uid/:date — pointage d'un jour
// ─────────────────────────────────────────────
router.get("/:uid/:date", async (req, res) => {
  const { uid, date } = req.params;

  try {
    const snapshot = await db.ref(`pointage/${uid}/${date}`).once("value");

    if (!snapshot.exists()) {
      return res.status(404).json({ message: `Aucun pointage trouvé pour ${uid} le ${date}.` });
    }

    const journee  = snapshot.val();
    const sessions = [];

    for (const key in journee) {
      if (key.startsWith("session")) {
        sessions.push({
          session: key,
          entree:  journee[key].entree || null,
          sortie:  journee[key].sortie || null,
        });
      }
    }

    return res.status(200).json({
      uid,
      date,
      nom:           journee.nom           || null,
      total_travail: journee.total_travail  || null,
      sessions,
    });

  } catch (error) {
    return res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
});

module.exports = router;
