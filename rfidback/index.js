const express = require("express");
const app = express();
require("dotenv").config();

app.use(express.json());

// ── Listener temps réel ──────────────────────
const { demarrerListenerPointage } = require("./service/pointageListener");
demarrerListenerPointage();

// ── Routes ───────────────────────────────────
const authRouter = require("./routes/auth");
const utilisateursRouter = require("./routes/utilisateurs");
const postesRouter = require("./routes/postes");
const pointageRouter = require("./routes/pointage");

app.use("/auth", authRouter);
app.use("/utilisateurs", utilisateursRouter);
app.use("/postes", postesRouter);
app.use("/pointage", pointageRouter);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Serveur démarré sur http://localhost:${PORT}`);
});