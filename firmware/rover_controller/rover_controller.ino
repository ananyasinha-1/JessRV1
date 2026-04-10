/*
 * ESP32 Rover Controller Firmware
 * Handles: Motor control + Servo + HTTP command endpoint
 *
 * Wiring (example):
 *   Motor driver IN1 -> GPIO 26
 *   Motor driver IN2 -> GPIO 27
 *   Motor driver IN3 -> GPIO 14
 *   Motor driver IN4 -> GPIO 12
 *   ENA (speed L) -> GPIO 25
 *   ENB (speed R) -> GPIO 33
 *   Servo -> GPIO 13
 *
 * Access point: connects to phone hotspot
 * Hostname: rover.local (mDNS)
 *
 * Endpoints:
 *   GET /move?dir=forward|back|left|right|stop
 *   GET /servo?angle=0-180
 *   GET /status
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <ESP32Servo.h>

// ─── Wi-Fi credentials (your phone hotspot) ───────────────────
const char* WIFI_SSID     = "YOUR_HOTSPOT_SSID";
const char* WIFI_PASSWORD = "YOUR_HOTSPOT_PASSWORD";
const char* HOSTNAME      = "rover";

// ─── Motor pins ───────────────────────────────────────────────
#define MOTOR_L_IN1  26
#define MOTOR_L_IN2  27
#define MOTOR_R_IN1  14
#define MOTOR_R_IN2  12
#define MOTOR_L_EN   25   // PWM speed left
#define MOTOR_R_EN   33   // PWM speed right

// ─── Servo pin ────────────────────────────────────────────────
#define SERVO_PIN    13

// ─── Safety timeout ───────────────────────────────────────────
#define CMD_TIMEOUT_MS 2000   // stop if no command in 2s

// ─── Speed 0-255 ──────────────────────────────────────────────
#define FULL_SPEED   200
#define TURN_SPEED   170

WebServer server(80);
Servo tiltServo;

unsigned long lastCommandTime = 0;
String lastDirection = "stop";

// ─── Motor helpers ────────────────────────────────────────────
void setMotors(bool l1, bool l2, bool r1, bool r2,
               int lSpeed = FULL_SPEED, int rSpeed = FULL_SPEED) {
  digitalWrite(MOTOR_L_IN1, l1);
  digitalWrite(MOTOR_L_IN2, l2);
  digitalWrite(MOTOR_R_IN1, r1);
  digitalWrite(MOTOR_R_IN2, r2);
  analogWrite(MOTOR_L_EN, lSpeed);
  analogWrite(MOTOR_R_EN, rSpeed);
}

void driveForward()  { setMotors(1,0, 1,0); }
void driveBackward() { setMotors(0,1, 0,1); }
void turnLeft()      { setMotors(0,1, 1,0, TURN_SPEED, TURN_SPEED); }
void turnRight()     { setMotors(1,0, 0,1, TURN_SPEED, TURN_SPEED); }
void motorStop()     { setMotors(0,0, 0,0, 0, 0); }

void applyDirection(String dir) {
  if      (dir == "forward") driveForward();
  else if (dir == "back")    driveBackward();
  else if (dir == "left")    turnLeft();
  else if (dir == "right")   turnRight();
  else                       motorStop();
  lastDirection = dir;
  lastCommandTime = millis();
}

// ─── HTTP handlers ────────────────────────────────────────────
void handleMove() {
  if (server.hasArg("dir")) {
    String dir = server.arg("dir");
    applyDirection(dir);
    server.send(200, "text/plain", "OK:" + dir);
  } else {
    server.send(400, "text/plain", "Missing dir param");
  }
}

void handleServo() {
  if (server.hasArg("angle")) {
    int angle = server.arg("angle").toInt();
    angle = constrain(angle, 0, 180);
    tiltServo.write(angle);
    lastCommandTime = millis();
    server.send(200, "text/plain", "SERVO:" + String(angle));
  } else {
    server.send(400, "text/plain", "Missing angle param");
  }
}

void handleStatus() {
  String json = "{\"status\":\"ok\",\"last\":\"" + lastDirection + "\",\"uptime\":" 
                + String(millis()) + "}";
  server.send(200, "application/json", json);
}

void handleNotFound() {
  server.send(404, "text/plain", "Not found");
}

// ─── Setup ────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Motor pins
  pinMode(MOTOR_L_IN1, OUTPUT);
  pinMode(MOTOR_L_IN2, OUTPUT);
  pinMode(MOTOR_R_IN1, OUTPUT);
  pinMode(MOTOR_R_IN2, OUTPUT);
  pinMode(MOTOR_L_EN, OUTPUT);
  pinMode(MOTOR_R_EN, OUTPUT);
  motorStop();

  // Servo
  ESP32PWM::allocateTimer(0);
  tiltServo.setPeriodHertz(50);
  tiltServo.attach(SERVO_PIN, 500, 2400);
  tiltServo.write(90);

  // Wi-Fi
  Serial.print("Connecting to ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected! IP: " + WiFi.localIP().toString());

  // mDNS
  if (!MDNS.begin(HOSTNAME)) {
    Serial.println("mDNS failed");
  } else {
    Serial.println("mDNS: rover.local");
    MDNS.addService("http", "tcp", 80);
  }

  // Routes
  server.on("/move",   HTTP_GET, handleMove);
  server.on("/servo",  HTTP_GET, handleServo);
  server.on("/status", HTTP_GET, handleStatus);
  server.onNotFound(handleNotFound);
  server.begin();

  Serial.println("HTTP server started");
  lastCommandTime = millis();
}

// ─── Loop ─────────────────────────────────────────────────────
void loop() {
  server.handleClient();

  // Safety watchdog: stop if no command received in CMD_TIMEOUT_MS
  if (millis() - lastCommandTime > CMD_TIMEOUT_MS &&
      lastDirection != "stop") {
    Serial.println("Watchdog: stopping rover");
    motorStop();
    lastDirection = "stop";
  }

  delay(2);
}
