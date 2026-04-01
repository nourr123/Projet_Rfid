const { db } = require("../firebase");

async function trouverPosteParUid(uid, statut) {
  const snapshot = await db.ref("postes").once("value");
  if (!snapshot.exists()) return null;

  const data = snapshot.val();
  
  for (const floor in data) {
    const etage = data[floor];
    for (const id in etage) {
      const poste = etage[id];
      if (poste.reservePar === uid && poste.statut === statut) {
        return { floor: floor, id: id };
      }
    }
  }
  return null;
}

function getTodayKey() {
  const now = new Date();
  const dd = String(now.getDate()).padStart(2, "0");
  const mm = String(now.getMonth() + 1).padStart(2, "0");
  const yyyy = now.getFullYear();
  return `${dd}-${mm}-${yyyy}`;
}

function demarrerListenerPointage() {
  console.log("👂 Listener pointage démarré...");

  const aujourdhui = getTodayKey();

  db.ref("pointage").on("child_added", (userSnapshot) => {
    const uid = userSnapshot.key;
    const dateRef = db.ref(`pointage/${uid}/${aujourdhui}`);

    dateRef.on("child_changed", async (sessionSnapshot) => {
      const sessionKey = sessionSnapshot.key;
      const session = sessionSnapshot.val();

      if (!sessionKey.startsWith("session")) return;

      const entree = session.entree || null;
      const sortie = session.sortie || null;

      if (entree && !sortie) {
        const posteInfo = await trouverPosteParUid(uid, "reserved");
        if (posteInfo) {
          await db.ref(`postes/${posteInfo.floor}/${posteInfo.id}`).update({ statut: "occupied" });
        }
      }

      if (entree && sortie) {
        const posteInfo = await trouverPosteParUid(uid, "occupied");
        if (posteInfo) {
          await db.ref(`postes/${posteInfo.floor}/${posteInfo.id}`).update({
            statut: "available",
            reservePar: null,
            prenom: null,
            dateReservation: null,
          });
        }
      }
    });

    dateRef.on("child_added", async (sessionSnapshot) => {
      const sessionKey = sessionSnapshot.key;
      const session = sessionSnapshot.val();

      if (!sessionKey.startsWith("session")) return;

      const entree = session.entree || null;
      const sortie = session.sortie || null;

      if (entree && !sortie) {
        const posteInfo = await trouverPosteParUid(uid, "reserved");
        if (posteInfo) {
          await db.ref(`postes/${posteInfo.floor}/${posteInfo.id}`).update({ statut: "occupied" });
        }
      }
    });
  });
}

module.exports = { demarrerListenerPointage };