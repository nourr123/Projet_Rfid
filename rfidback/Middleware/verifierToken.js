const jwt = require("jsonwebtoken");

// ─── Vérifier que le token est valide ─────────
const verifierToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  // 1. Vérifier que le header Authorization existe
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Token manquant. Connectez-vous d'abord." });
  }

  // 2. Extraire le token (enlever "Bearer ")
  const token = authHeader.split(" ")[1];

  try {
    // 3. Vérifier et décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 4. Attacher les infos au request pour la suite
    req.user = decoded; // { uid, email, role }
    next();

  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({ message: "Token expiré. Reconnectez-vous." });
    }
    return res.status(401).json({ message: "Token invalide." });
  }
};

// ─── Vérifier que le token est admin ──────────
const verifierAdmin = (req, res, next) => {
  verifierToken(req, res, () => {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Accès refusé. Rôle admin requis." });
    }
    next();
  });
};

module.exports = { verifierToken, verifierAdmin };