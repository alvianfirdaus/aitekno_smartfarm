/*
 * PROYEK_SMARTFARM_LENGKAP (Versi ringkas – soil moisture analog + NPK saja)
 * Perubahan:
 * - Soil moisture dipisah ke sensor analog di GPIO1 (ADC1_CH0).
 * - pH, Suhu Tanah, dan Konduktivitas DIHAPUS dari seluruh alur (LCD/Serial/CSV/Firebase).
 * - NPK (N, P, K) tetap dibaca via Modbus RS485.
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ModbusMaster.h>
#include <DHT.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <SPI.h>
#include <SD.h>
#include <RTClib.h>

// ---------------- Pin & Objek ----------------

// RS485 NPK Sensor
const byte rxPin = 16;         // RX2
const byte txPin = 15;         // TX2
HardwareSerial modul(1);       // UART2
ModbusMaster node;
uint8_t modbusResult;

// DHT21 (AM2301A) — suhu & kelembaban udara
#define DHTPIN 2
#define DHTTYPE DHT21
DHT dht(DHTPIN, DHTTYPE);

// LCD I2C
const int I2C_SDA_PIN = 8;
const int I2C_SCL_PIN = 9;
LiquidCrystal_I2C lcd(0x27, 20, 4);

// RTC (DS3231)
RTC_DS3231 rtc;

// SD Card (SPI)
const int chipSelect = 10;

// Relay Pompa
#define RELAY_POMPA1_PIN 21
#define RELAY_POMPA2_PIN 47
#define RELAY_POMPA3_PIN 14
#define RELAY_POMPA4_PIN 38

// Soil moisture analog (ESP32-S3)
const int SOIL_ANALOG_PIN = 1; // GPIO1 / ADC1_CH0

// Wi-Fi
const char* ssid = "JTI-POLINEMA";
const char* password = "jtifast!";

// Firebase
const char* firebaseHost = "programsiramtanamotomatisb-default-rtdb.asia-southeast1.firebasedatabase.app/";
const char* firebaseAuth = "AIzaSyCK3U0VIltL-N0m8btw0vfBiyrL4oHekWs";
FirebaseData firebaseData;
FirebaseConfig firebaseConfig;
FirebaseAuth auth;
bool isWiFiConnected = false;
bool isFirebaseReady = false;

// NTP
const int timeZone = 7; // GMT+7
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", timeZone * 3600);

// Retry & interval
unsigned long lastFailedNetworkAttempt = 0;
const unsigned long reconnectInterval = 120000;
unsigned long lastHistoryUpload = 0;
const unsigned long historyUploadInterval = 30000;
unsigned long lastSDLog = 0;
const unsigned long sdLogInterval = 60000;
#define MAIN_LOOP_INTERVAL 3000
long previousMillis;

// LCD multi-screen (hanya 2 layar sekarang)
int lcdScreen = 0;
unsigned long lastLCDUpdate = 0;
const unsigned long lcdUpdateInterval = 5000;

// ---------------- Variabel Data ----------------
float soilMoisture = -1.0;   // % dari sensor analog
float nitrogen = -1.0;       // mg/kg (Modbus)
float phosphorus = -1.0;     // mg/kg (Modbus)
float potassium = -1.0;      // mg/kg (Modbus)
float airHumidity = -1.0;    // %RH (DHT21)
float airTemperature = -1.0; // °C   (DHT21)

// ---------------- Util SD ----------------
void logToSDCard(String filename, String data) {
  if (SD.cardType() == CARD_NONE) {
    Serial.println("SD Card tidak tersedia.");
    return;
  }
  File file = SD.open(filename, FILE_APPEND);
  if (!file) {
    Serial.print("Gagal buka "); Serial.println(filename);
    return;
  }
  file.println(data);
  file.close();
}

// ---------------- Soil moisture analog -> % ----------------
float readSoilMoisturePercent() {
  int raw = analogRead(SOIL_ANALOG_PIN);
  raw = constrain(raw, 0, 4095);
  long pct = map(raw, 4095, 0, 0, 100); // kering 4095 -> 0%, basah 0 -> 100%
  pct = constrain(pct, 0, 100);
  return (float)pct;
}

// ---------------- NTP Sync -> RTC ----------------
void syncNTPTime() {
  if (!isWiFiConnected) return;
  timeClient.begin();
  int retry = 0;
  while (!timeClient.forceUpdate() && retry < 10) {
    delay(1000);
    retry++;
  }
  if (retry < 10) {
    time_t ntpTime = timeClient.getEpochTime();
    rtc.adjust(DateTime(ntpTime));
    Serial.println("RTC updated from NTP");
  } else {
    Serial.println("NTP sync gagal");
  }
}

// ---------------- WiFi ----------------
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) { isWiFiConnected = true; return; }
  Serial.print("Connecting WiFi");
  lcd.setCursor(0,0); lcd.print("Connecting WiFi...");
  WiFi.begin(ssid, password);
  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - startAttempt < 10000)) {
    Serial.print(".");
    delay(500);
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected: " + WiFi.localIP().toString());
    lcd.clear(); lcd.setCursor(0,0); lcd.print("WiFi Connected");
    isWiFiConnected = true;
  } else {
    Serial.println("\nWiFi failed");
    lcd.clear(); lcd.setCursor(0,0); lcd.print("WiFi Failed");
    isWiFiConnected = false;
  }
}

// ---------------- Firebase ----------------
void initFirebase() {
  if (!isWiFiConnected) { isFirebaseReady = false; return; }
  firebaseConfig.host = firebaseHost;
  firebaseConfig.signer.tokens.legacy_token = firebaseAuth;
  Firebase.begin(&firebaseConfig, &auth);
  Firebase.reconnectWiFi(true);
  isFirebaseReady = Firebase.ready();
  Serial.println(isFirebaseReady ? "Firebase ready" : "Firebase not ready");
}

// ---------------- Timestamp ----------------
String getAccurateTimestamp() {
  char ts[30];
  if (rtc.begin() && !rtc.lostPower()) {
    DateTime now = rtc.now();
    sprintf(ts, "%04d-%02d-%02d %02d:%02d:%02d",
            now.year(), now.month(), now.day(),
            now.hour(), now.minute(), now.second());
  } else if (timeClient.isTimeSet()) {
    time_t now = timeClient.getEpochTime();
    struct tm *lt = localtime(&now);
    sprintf(ts, "%04d-%02d-%02d %02d:%02d:%02d",
            lt->tm_year + 1900, lt->tm_mon + 1, lt->tm_mday,
            lt->tm_hour, lt->tm_min, lt->tm_sec);
  } else {
    sprintf(ts, "%lu_ms", millis());
  }
  return String(ts);
}

// ---------------- Kirim buffer ke Firebase ----------------
void processBufferedData() {
  if (SD.cardType() == CARD_NONE || !isFirebaseReady) return;

  File bufferFile = SD.open("/firebase_buffer.csv", FILE_READ);
  if (!bufferFile) return;

  File tempFile = SD.open("/firebase_temp_buffer.csv", FILE_WRITE);
  if (!tempFile) { bufferFile.close(); return; }

  bool changed = false, hasRemain = false;
  String line;
  while (bufferFile.available()) {
    line = bufferFile.readStringUntil('\n'); line.trim();
    if (!line.length()) continue;

    int commaIndex = line.indexOf(',');
    if (commaIndex == -1) { tempFile.println(line); hasRemain = true; continue; }

    String timestamp = line.substring(0, commaIndex);
    String jsonStr = line.substring(commaIndex + 1);

    FirebaseJson json;
    if (json.setJsonData(jsonStr)) {
      String datePart = timestamp.substring(0, 10);
      String timePart = timestamp.substring(11, 16);
      String historyPath = "/004025002/zhistory/" + datePart + "/" + timePart;
      if (Firebase.updateNode(firebaseData, historyPath, json)) {
        changed = true;
      } else {
        tempFile.println(line); hasRemain = true;
      }
    } else {
      tempFile.println(line); hasRemain = true;
    }
  }
  bufferFile.close(); tempFile.close();

  if (changed || !hasRemain) {
    SD.remove("/firebase_buffer.csv");
    SD.rename("/firebase_temp_buffer.csv", "/firebase_buffer.csv");
  } else {
    SD.remove("/firebase_temp_buffer.csv");
  }
}

// ---------------- Setup ----------------
void setup() {
  Serial.begin(115200);
  while (!Serial);

  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  lcd.init(); lcd.backlight();
  lcd.print("SmartFarm Booting...");
  delay(1200); lcd.clear();

  pinMode(RELAY_POMPA1_PIN, OUTPUT);
  pinMode(RELAY_POMPA2_PIN, OUTPUT);
  pinMode(RELAY_POMPA3_PIN, OUTPUT);
  pinMode(RELAY_POMPA4_PIN, OUTPUT);
  digitalWrite(RELAY_POMPA1_PIN, LOW);
  digitalWrite(RELAY_POMPA2_PIN, LOW);
  digitalWrite(RELAY_POMPA3_PIN, LOW);
  digitalWrite(RELAY_POMPA4_PIN, LOW);

  // Modbus NPK
  modul.begin(9600, SERIAL_8N1, rxPin, txPin);
  node.begin(2, modul); // Slave ID 2

  dht.begin();

  // RTC
  if (!rtc.begin()) {
    Serial.println("RTC tidak ditemukan");
  } else if (rtc.lostPower()) {
    Serial.println("RTC lost power; akan sync NTP jika tersedia");
  }

  // SD
  if (!SD.begin(chipSelect)) {
    Serial.println("SD Card mount failed");
    lcd.setCursor(0, 3); lcd.print("SD Failed");
  } else {
    if (!SD.exists("/data.csv")) {
      // Header baru tanpa soilTemperature, conductivity, pH
      logToSDCard("/data.csv",
        "Timestamp,SoilMoisture,AirTemperature,AirHumidity,Nitrogen,Phosphorus,Potassium,PumpStatus,Mode,ManualPumpControl");
    }
    if (!SD.exists("/firebase_buffer.csv")) {
      // tanpa header
    }
  }

  connectWiFi();
  initFirebase();
  syncNTPTime();

  previousMillis = millis();
}

// ---------------- LCD ----------------
void updateLCD(int mode, int statusPompa) {
  if (millis() - lastLCDUpdate >= lcdUpdateInterval) {
    lcdScreen = (lcdScreen + 1) % 2; // sekarang cuma 2 layar (0 & 1)
    lastLCDUpdate = millis();
    lcd.clear();
  }

  if (lcdScreen == 0) {
    // Layar 0: Udara & Kelembaban Tanah + Status
    lcd.setCursor(0, 0);
    lcd.print("Udara:");
    if (airTemperature >= 0) lcd.print(airTemperature, 1); else lcd.print("N/A");
    lcd.print((char)223); lcd.print("C/");
    if (airHumidity >= 0) lcd.print(airHumidity, 0); else lcd.print("N/A");
    lcd.print("%");

    lcd.setCursor(0, 1);
    lcd.print("Tanah:");
    if (soilMoisture >= 0) lcd.print(soilMoisture, 0); else lcd.print("N/A");
    lcd.print("%RH ");
    if (soilMoisture >= 0) {
      if (soilMoisture > 70) lcd.print("Basah");
      else if (soilMoisture > 40) lcd.print("Normal");
      else lcd.print("Kering");
    } else lcd.print("N/A  ");

    lcd.setCursor(0, 2);
    lcd.print("Mode:");
    if (isFirebaseReady) lcd.print(mode == 1 ? "Otomatis" : "Manual");
    else lcd.print("Offline");

    lcd.setCursor(0, 3);
    lcd.print("Pompa:");
    lcd.print(statusPompa == 1 ? "Nyala" : "Mati");
  } else {
    // Layar 1: NPK saja
    lcd.setCursor(0, 0); lcd.print("Kadar Nutrisi (mg/kg)");
    lcd.setCursor(0, 1); lcd.print("N:"); if (nitrogen   >= 0) lcd.print((int)nitrogen);   else lcd.print("N/A");
    lcd.setCursor(8, 1); lcd.print("P:"); if (phosphorus >= 0) lcd.print((int)phosphorus); else lcd.print("N/A");
    lcd.setCursor(0, 2); lcd.print("K:"); if (potassium  >= 0) lcd.print((int)potassium);  else lcd.print("N/A");
  }
}

// ---------------- Loop ----------------
void loop() {
  // Reconnect
  if (!isWiFiConnected || !isFirebaseReady) {
    if (millis() - lastFailedNetworkAttempt >= reconnectInterval) {
      connectWiFi();
      initFirebase();
      syncNTPTime();
      lastFailedNetworkAttempt = millis();
    }
  }

  if (millis() - previousMillis >= MAIN_LOOP_INTERVAL) {
    // Udara (DHT)
    airHumidity = dht.readHumidity();
    airTemperature = dht.readTemperature();
    if (isnan(airHumidity) || isnan(airTemperature)) {
      airHumidity = -1; airTemperature = -1;
    }

    // Soil moisture analog (PIN 1)
    soilMoisture = readSoilMoisturePercent();

    // NPK via Modbus (hanya N/P/K) – register 0x0004..0x0006
    modbusResult = node.readHoldingRegisters(0x0004, 3);
    if (modbusResult == node.ku8MBSuccess) {
      nitrogen   = (float)node.getResponseBuffer(0x0000);
      phosphorus = (float)node.getResponseBuffer(0x0001);
      potassium  = (float)node.getResponseBuffer(0x0002);
    } else {
      nitrogen = phosphorus = potassium = -1.0;
      Serial.print("NPK read fail, code: "); Serial.println(modbusResult);
    }

    // Mode & Manual dari Firebase (jika ready)
    int mode = 1;
    int manualPumpControl = 0;
    if (isFirebaseReady) {
      if (Firebase.getInt(firebaseData, "/004025002/mode")) mode = firebaseData.intData();
      if (Firebase.getInt(firebaseData, "/004025002/manualPumpControl")) manualPumpControl = firebaseData.intData();
    } else {
      mode = 1; manualPumpControl = 0;
    }

    // Kontrol pompa (berdasarkan soilMoisture analog)
    int statusPompa = 0;
    if (mode == 1) {
      if (soilMoisture >= 0 && soilMoisture <= 40) {
        digitalWrite(RELAY_POMPA1_PIN, HIGH);
        digitalWrite(RELAY_POMPA2_PIN, HIGH);
        digitalWrite(RELAY_POMPA3_PIN, HIGH);
        digitalWrite(RELAY_POMPA4_PIN, HIGH);
        statusPompa = 1;
      } else {
        digitalWrite(RELAY_POMPA1_PIN, LOW);
        digitalWrite(RELAY_POMPA2_PIN, LOW);
        digitalWrite(RELAY_POMPA3_PIN, LOW);
        digitalWrite(RELAY_POMPA4_PIN, LOW);
        statusPompa = 0;
      }
    } else {
      if (manualPumpControl == 1) {
        digitalWrite(RELAY_POMPA1_PIN, HIGH);
        digitalWrite(RELAY_POMPA2_PIN, HIGH);
        digitalWrite(RELAY_POMPA3_PIN, HIGH);
        digitalWrite(RELAY_POMPA4_PIN, HIGH);
        statusPompa = 1;
      } else {
        digitalWrite(RELAY_POMPA1_PIN, LOW);
        digitalWrite(RELAY_POMPA2_PIN, LOW);
        digitalWrite(RELAY_POMPA3_PIN, LOW);
        digitalWrite(RELAY_POMPA4_PIN, LOW);
        statusPompa = 0;
      }
    }

    // LCD
    updateLCD(mode, statusPompa);

    // Serial log (ringkas – tanpa pH, soilTemp, konduktivitas)
    Serial.println("\n--- Data Sensor & Status ---");
    Serial.print("Soil Moisture (analog) = "); if (soilMoisture >= 0) Serial.print(soilMoisture); else Serial.print("N/A"); Serial.println(" %RH");
    Serial.print("N = "); if (nitrogen   >= 0) Serial.print(nitrogen);   else Serial.print("N/A"); Serial.println(" mg/kg");
    Serial.print("P = "); if (phosphorus >= 0) Serial.print(phosphorus); else Serial.print("N/A"); Serial.println(" mg/kg");
    Serial.print("K = "); if (potassium  >= 0) Serial.print(potassium);  else Serial.print("N/A"); Serial.println(" mg/kg");
    Serial.print("Air Temp = "); if (airTemperature >= 0) Serial.print(airTemperature); else Serial.print("N/A"); Serial.println(" C");
    Serial.print("Air RH   = "); if (airHumidity   >= 0) Serial.print(airHumidity);   else Serial.print("N/A"); Serial.println(" %");
    Serial.print("Mode = "); Serial.print(mode == 1 ? "Otomatis" : "Manual");
    Serial.print(" | Pompa = "); Serial.println(statusPompa == 1 ? "Nyala" : "Mati");
    Serial.println("----------------------------");

    // Timestamp
    String currentTimestamp = getAccurateTimestamp();

    // JSON Firebase (tanpa pH/soilTemp/cond)
    FirebaseJson json;
    json.set("soilMoisture", String(soilMoisture, 0));
    json.set("airTemperature", String(airTemperature, 1));
    json.set("airHumidity", String(airHumidity, 1));
    json.set("nitrogen", String(nitrogen, 0));
    json.set("phosphorus", String(phosphorus, 0));
    json.set("potassium", String(potassium, 0));
    json.set("statusPompa", statusPompa);
    json.set("mode", mode);
    json.set("manualPumpControl", manualPumpControl);

    // CSV realtime (header sudah disesuaikan)
    String dataLogRealtime = currentTimestamp + "," +
                             String(soilMoisture, 0) + "," +
                             String(airTemperature, 1) + "," +
                             String(airHumidity, 1) + "," +
                             String(nitrogen, 0) + "," +
                             String(phosphorus, 0) + "," +
                             String(potassium, 0) + "," +
                             String(statusPompa) + "," +
                             String(mode) + "," +
                             String(manualPumpControl);

    if (millis() - lastSDLog >= sdLogInterval) {
      logToSDCard("/data.csv", dataLogRealtime);
      lastSDLog = millis();
    }

    // Buffer untuk Firebase History
    String dataToBuffer = currentTimestamp + "," + json.raw();
    logToSDCard("/firebase_buffer.csv", dataToBuffer);

    // Kirim realtime ke Firebase
    if (isFirebaseReady) {
      String path = "/004025002";
      if (!Firebase.updateNode(firebaseData, path, json)) {
        Serial.print("Firebase realtime gagal: ");
        Serial.println(firebaseData.errorReason());
      }
    }

    // Proses buffer -> Firebase history per interval
    if (isFirebaseReady && (millis() - lastHistoryUpload >= historyUploadInterval)) {
      processBufferedData();
      lastHistoryUpload = millis();
    }

    previousMillis = millis();
  }
}
