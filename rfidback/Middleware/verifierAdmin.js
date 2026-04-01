const jwt = require("jsonwebtoken");
const { db } = require("../firebase");

/**
 * Middleware — vérifie que l'appelant est bien un admin via le token JWT
 */
const verifierAdmin = async (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Token manquant ou format invalide." });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    if (decoded.role !== "admin") {
      return res.status(403).json({ message: "Accès refusé. Rôle admin requis." });
    }

    const snapshot = await db.ref(`autorized/${decoded.uid}`).once("value");
    
    if (!snapshot.exists()) {
      return res.status(403).json({ message: "Utilisateur introuvable dans Firebase." });
    }

    const user = snapshot.val();

    if (!user.autorise) {
      return res.status(403).json({ message: "Compte désactivé." });
    }

    req.admin = user;
    req.adminUid = decoded.uid;
    next();

  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({ message: "Token expiré. Reconnectez-vous." });
    }
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({ message: "Token invalide." });
    }
    return res.status(500).json({ message: "Erreur vérification admin.", error: error.message });
  }
};

module.exports = verifierAdmin;