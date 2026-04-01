#include <WiFi.h>
#include <FirebaseESP32.h>
#include <SPI.h>
#include <MFRC522.h>
#include <time.h>

// ─── WiFi ─────────────────────────────────────────────
#define WIFI_SSID     "Airbox-F95A"
#define WIFI_PASSWORD "GCLADGVJ"

// ─── Firebase ─────────────────────────────────────────
#define FIREBASE_HOST "pointage-c51ed-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "bGeGslB5exdPEOvLtIgJcC4ZkjxYas1fp8eO0o1n"
#define FB_AUTORIZED  "/autorized"

// ─── RFID ─────────────────────────────────────────────
#define SS_PIN    5
#define RST_PIN   22
#define RELAY_PIN 33
#define BUZZER_PIN 25

MFRC522 rfid(SS_PIN, RST_PIN);
FirebaseData fbdo;
FirebaseData fbdo2;
FirebaseAuth auth;
FirebaseConfig config;

// ─── État en mémoire ──────────────────────────────────
struct EtatUID {
  String uid;
  String nomComplet;
  int    session;
  bool   enAttenteSortie;
  String heureEntree;
  int    totalSecondes;
};

#define MAX_UIDS 10
EtatUID etats[MAX_UIDS];
int nbUids = 0;

byte lastUID[10];
byte lastUIDSize = 0;
unsigned long lastScanTime = 0;
#define SCAN_DELAY 2000

// ─── PORTE NON BLOQUANTE ⚡ ───────────────────────────
unsigned long porteStart = 0;
bool porteActive = false;

// ─── Helpers temps ────────────────────────────────────
String getDate() {
  struct tm t;
  if (!getLocalTime(&t)) return "00-00-0000";
  char buf[11];
  strftime(buf, sizeof(buf), "%d-%m-%Y", &t);
  return String(buf);
}

String getHeure() {
  struct tm t;
  if (!getLocalTime(&t)) return "00:00:00";
  char buf[9];
  strftime(buf, sizeof(buf), "%H:%M:%S", &t);
  return String(buf);
}

int timeToSeconds(String t) {
  return t.substring(0,2).toInt()*3600
       + t.substring(3,5).toInt()*60
       + t.substring(6,8).toInt();
}

String secondsToHM(int s) {
  return String(s/3600) + "h " + String((s%3600)/60) + "m";
}

// ─── Firebase reconnect ⚡ ───────────────────────────
void reconnecterFirebase() {
  if (!Firebase.ready()) {
    Serial.println("🔄 Reconnexion Firebase...");
    Firebase.begin(&config, &auth);
  }
}

// ─── Nom complet ──────────────────────────────────────
String getNomComplet(String uid) {
  String prenom = "";
  String nom    = "";
  reconnecterFirebase();

  if (Firebase.getString(fbdo2, String(FB_AUTORIZED) + "/" + uid + "/prenom"))
    prenom = fbdo2.stringData();

  if (Firebase.getString(fbdo2, String(FB_AUTORIZED) + "/" + uid + "/nom"))
    nom = fbdo2.stringData();

  return prenom + " " + nom;
}

// ─── Charger état Firebase ─────────────────────────────
void recupererEtatDepuisFirebase(String uid, String nomComplet) {
  String date = getDate();
  String basePath = "/pointage/" + uid + "/" + date;

  int totalSecondes = 0;
  int derniereSession = 1;
  bool enAttente = false;
  String heureEntree = "";

  for (int i = 1; i <= 20; i++) {
    String entree = "";
    String sortie = "";

    reconnecterFirebase();

    if (Firebase.getString(fbdo2, basePath + "/session" + String(i) + "/entree"))
      entree = fbdo2.stringData();

    if (entree == "") break;

    if (Firebase.getString(fbdo2, basePath + "/session" + String(i) + "/sortie"))
      sortie = fbdo2.stringData();

    if (sortie == "") {
      derniereSession = i;
      enAttente = true;
      heureEntree = entree;
    } else {
      int diff = timeToSeconds(sortie) - timeToSeconds(entree);
      if (diff > 0) totalSecondes += diff;
      derniereSession = i + 1;
      enAttente = false;
    }
  }

  EtatUID* e = &etats[nbUids++];
  e->uid = uid;
  e->nomComplet = nomComplet;
  e->session = derniereSession;
  e->enAttenteSortie = enAttente;
  e->heureEntree = heureEntree;
  e->totalSecondes = totalSecondes;
}

// ─── GET ETAT ─────────────────────────────────────────
EtatUID* getEtat(String uid) {
  for (int i = 0; i < nbUids; i++)
    if (etats[i].uid == uid) return &etats[i];

  if (nbUids < MAX_UIDS) {
    String nom = getNomComplet(uid);
    recupererEtatDepuisFirebase(uid, nom);
    return &etats[nbUids - 1];
  }
  return nullptr;
}

// ─── POINTAGE ─────────────────────────────────────────
void traiterPointage(String uid) {
  EtatUID* e = getEtat(uid);
  if (!e) return;

  String date = getDate();
  String heure = getHeure();
  String basePath = "/pointage/" + uid + "/" + date;

  reconnecterFirebase();

  if (!e->enAttenteSortie) {
    e->heureEntree = heure;
    e->enAttenteSortie = true;

    Firebase.setString(fbdo, basePath + "/nom", e->nomComplet);
    Firebase.setString(fbdo, basePath + "/session" + String(e->session) + "/entree", heure);

  } else {
    int duree = timeToSeconds(heure) - timeToSeconds(e->heureEntree);
    if (duree < 0) duree = 0;

    e->totalSecondes += duree;
    e->enAttenteSortie = false;

    Firebase.setString(fbdo, basePath + "/session" + String(e->session) + "/sortie", heure);
    Firebase.setString(fbdo, basePath + "/total_travail", secondsToHM(e->totalSecondes));

    e->session++;
  }
}

// ─── BUZZER RAPIDE ⚡ ──────────────────────────────────
void buzzerAutorise() {
  for (int i = 0; i < 2; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delayMicroseconds(120000);
    digitalWrite(BUZZER_PIN, LOW);
    delayMicroseconds(120000);
  }
}

void buzzerRefuse() {
  for (int i = 0; i < 4; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delayMicroseconds(70000);
    digitalWrite(BUZZER_PIN, LOW);
    delayMicroseconds(70000);
  }
}

// ─── PORTE NON BLOQUANTE ⚡ ───────────────────────────
void ouvrirPorte() {
  digitalWrite(RELAY_PIN, HIGH);
  buzzerAutorise();

  porteStart = millis();
  porteActive = true;

  Serial.println("🚪 Porte ouverte");
}

// ─── SETUP ────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  pinMode(RELAY_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) delay(200);

  configTime(3600, 0, "pool.ntp.org");

  config.database_url = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  fbdo.setResponseSize(4096);
  fbdo2.setResponseSize(4096);

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  SPI.begin(18, 19, 23, SS_PIN);
  rfid.PCD_Init();
  rfid.PCD_SetAntennaGain(rfid.RxGain_max);

  Serial.println("✅ READY");
}

// ─── LOOP ULTRA RAPIDE ⚡ ─────────────────────────────
void loop() {

  // 🚪 fermeture non bloquante
  if (porteActive && millis() - porteStart >= 3000) {
    digitalWrite(RELAY_PIN, LOW);
    porteActive = false;
    Serial.println("🔒 Porte fermée");
  }

  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;

  unsigned long now = millis();
  if (rfid.uid.size == lastUIDSize &&
      memcmp(rfid.uid.uidByte, lastUID, rfid.uid.size) == 0 &&
      now - lastScanTime < SCAN_DELAY) {
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
    return;
  }

  lastUIDSize = rfid.uid.size;
  memcpy(lastUID, rfid.uid.uidByte, rfid.uid.size);
  lastScanTime = now;

  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();

  bool autorise = false;

  for (int i = 0; i < 2; i++) {
    reconnecterFirebase();

    if (Firebase.getBool(fbdo, String(FB_AUTORIZED) + "/" + uid + "/autorise")) {
      autorise = fbdo.boolData();
      break;
    }

    delay(200);
  }

  if (autorise) {
    ouvrirPorte();
    traiterPointage(uid);
  } else {
    buzzerRefuse();
  }

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
}