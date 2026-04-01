const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialiser Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://pointage-c51ed-default-rtdb.firebaseio.com"
  });
}

const db = admin.database();

async function initAllPostes() {
  console.log("🚀 Création automatique de tous les postes...");
  console.log("⚠️  ATTENTION: Les anciens postes vont être supprimés!");

  try {
    // SUPPRIMER LES ANCIENNES DONNÉES
    console.log("\n🗑️ Suppression des anciens postes...");
    await db.ref("postes").remove();
    console.log("✅ Anciens postes supprimés");

    // ===========================================
    // FLOOR 01 - 15 postes en 3 rangées
    // ===========================================
    const floor01 = {};
    
    // RANGÉE 1: A1 à A5 (5 postes)
    for (let i = 1; i <= 5; i++) {
      floor01[`A${i}`] = {
        numero: `A${i}`,
        statut: "available",
        reservePar: null,
        prenom: null,
        dateReservation: null
      };
    }
    
    // RANGÉE 2: B1 à B5 (5 postes)
    for (let i = 1; i <= 5; i++) {
      // B4 et B5 sont bloqués
      const statut = (i === 4 || i === 5) ? "blocked" : "available";
      floor01[`B${i}`] = {
        numero: `B${i}`,
        statut: statut,
        reservePar: null,
        prenom: null,
        dateReservation: null
      };
    }
    
    // RANGÉE 3: C1 à C5 (5 postes)
    for (let i = 1; i <= 5; i++) {
      floor01[`C${i}`] = {
        numero: `C${i}`,
        statut: "available",
        reservePar: null,
        prenom: null,
        dateReservation: null
      };
    }

    // ===========================================
    // FLOOR 02 - 13 postes en 3 rangées
    // ===========================================
    const floor02 = {};
    
    // RANGÉE 1: D1 à D4 (4 postes)
    for (let i = 1; i <= 4; i++) {
      floor02[`D${i}`] = {
        numero: `D${i}`,
        statut: "available",
        reservePar: null,
        prenom: null,
        dateReservation: null
      };
    }
    
    // RANGÉE 2: E1 à E5 (5 postes)
    for (let i = 1; i <= 5; i++) {
      // E4 et E5 sont bloqués
      const statut = (i === 4 || i === 5) ? "blocked" : "available";
      floor02[`E${i}`] = {
        numero: `E${i}`,
        statut: statut,
        reservePar: null,
        prenom: null,
        dateReservation: null
      };
    }
    
    // RANGÉE 3: F1 à F4 (4 postes)
    for (let i = 1; i <= 4; i++) {
      floor02[`F${i}`] = {
        numero: `F${i}`,
        statut: "available",
        reservePar: null,
        prenom: null,
        dateReservation: null
      };
    }

    // SAUVEGARDER DANS FIREBASE
    console.log("\n📝 Création des nouveaux postes...");
    
    await db.ref("postes/Floor01").set(floor01);
    console.log("✅ Floor01 créé avec 15 postes en 3 rangées:");
    console.log("   - Rangée A (A1-A5): 5 postes disponibles");
    console.log("   - Rangée B (B1-B5): 3 disponibles + 2 bloqués (B4,B5)");
    console.log("   - Rangée C (C1-C5): 5 postes disponibles");

    await db.ref("postes/Floor02").set(floor02);
    console.log("✅ Floor02 créé avec 13 postes en 3 rangées:");
    console.log("   - Rangée D (D1-D4): 4 postes disponibles");
    console.log("   - Rangée E (E1-E5): 3 disponibles + 2 bloqués (E4,E5)");
    console.log("   - Rangée F (F1-F4): 4 postes disponibles");

    // VÉRIFICATION
    console.log("\n🔍 Vérification...");
    const snapshot = await db.ref("postes").once("value");
    const data = snapshot.val();
    
    if (data) {
      console.log("📊 Structure finale dans Firebase:");
      if (data.Floor01) console.log(`   Floor01: ${Object.keys(data.Floor01).length} postes`);
      if (data.Floor02) console.log(`   Floor02: ${Object.keys(data.Floor02).length} postes`);
    }

    console.log("\n🎉 TOTAL: 28 postes créés avec succès !");
    console.log("✅ Les postes devraient maintenant s'afficher correctement dans l'application");

  } catch (error) {
    console.error("❌ Erreur:", error);
  }
  
  process.exit(0);
}

initAllPostes();