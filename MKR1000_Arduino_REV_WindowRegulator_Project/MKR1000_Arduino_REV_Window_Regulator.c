/* Dylan Flores
CpE 417
2001549196
Final Project */
#define BLYNK_TEMPLATE_ID "TMPLoVVf9Ycy"
#define BLYNK_DEVICE_NAME "Final"
#define BLYNK_AUTH_TOKEN "s4qBIA7ZM32InWbJhfnkWLKc78M4X2bW"
#define BLYNK_PRINT SerialUSB
#include <SPI.h>
#include <WiFi101.h>
#include <ArduinoMqttClient.h>
#include <BlynkSimpleWiFiShield101.h>
#include "ThingSpeak.h"
#define tempPin A1
#define humidityPin A2
#define sensorPin 7
#define solenoid 8
#define solenoid2 9
//const char ssid[] = "Dylan's iPhone";
const char ssid[] = "ECE_Labs";
const char pass[] = "348#ECEWiFi";
const char auth[] = BLYNK_AUTH_TOKEN;
int status = WL_IDLE_STATUS;     // the Wifi radio's status
unsigned long myChannelNumber = 1981479;
const char* myWriteAPIKey = "2T2OAUK7F74HM377";


WiFiClient client;
MqttClient mqttClient(client);
const char broker[] = "test.mosquitto.org";
int port = 1883;
const char topic[] = "final_sensors";
const char topic1[] = "final_sensors";
const char topic2[] = "final_sensors";
int estimate_sec = 0;
static float distance, temp, humidity;
bool firstActuatorOpen = false;
bool secondActuatorOpen = false;


// Set up pins and initialize
void setup() {
 // put your setup code here, to run once:
 Serial.begin(9600); // BAUD rate 9600 serial display terminal
 SerialUSB.begin(115200);
 Serial.println("Attempting to connect to WPA network...");
 status = WiFi.begin(ssid, pass);
 if(status != WL_CONNECTED) {
   Serial.println("Couldn't get a wifi connection");
   while(true);
 }
 else {
   Serial.print("Connected to network: ");
   Serial.println(ssid);
 }
 Serial.println("You're connected to the network\n");
//connection to the broker
 Serial.print("Attempting to connect to the MQTT broker: ");
 Serial.println(broker);
//connection to the broker failed
 if (!mqttClient.connect(broker, port)) {
   Serial.print("MQTT connection failed! Error code = ");
   Serial.println(mqttClient.connectError());
   while (1);
 }
  Serial.println("Connected to the MQTT broker!\n");
 pinMode(tempPin, INPUT);
 pinMode(humidityPin, INPUT);
 pinMode(solenoid, OUTPUT);
 pinMode(solenoid2, OUTPUT);
 Serial.println("Connecting to the Blynk Application...");
 Blynk.begin(auth, ssid, pass); // start blynk
 Serial.println("Connected to the Blynk App! \n Connecting to ThingSpeak Channel..");
 delay(1000);
 ThingSpeak.begin(client);
 delay(1000);
 Serial.println("Connected to ThingSpeak Channel!\n");
}
// Loop forever
void loop() {
 mqttClient.poll();
 sensor_temp();
 sensor_humidity();
 sensor();
 actuator();
 print_info_monitor();
 delay(1000);
 mqTTClient();
// thingSpeak();
 Blynk.run();
 Blynk.virtualWrite(V0, temp);
 Blynk.virtualWrite(V1, humidity);
 Blynk.virtualWrite(V2, distance);
 }


void thingSpeak(){
 ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
 ThingSpeak.setField(1, temp);
 ThingSpeak.setField(2, humidity);
 ThingSpeak.setField(3, distance);
 Serial.println("Temperature, humidity, & distance window opened datas sent to the cloud\n");
}
void mqTTClient(){
 Serial.println("Sending message to topic: ");
 mqttClient.beginMessage(topic);
 mqttClient.println("************************************************************************************");
 mqttClient.print("Temperature in Deg. Farenheit: ");
 mqttClient.print(temp);
 mqttClient.println(" F");
 mqttClient.endMessage();


 mqttClient.beginMessage(topic1);
 mqttClient.print("Humidity is: ");
 mqttClient.print(humidity);
 mqttClient.println("% ");
 mqttClient.endMessage();


 mqttClient.beginMessage(topic2);
 mqttClient.print("Distance window is open by: ");
 mqttClient.print(distance);
 mqttClient.println(" cm ");
 mqttClient.println("************************************************************************************");
 mqttClient.println();
 mqttClient.endMessage();
}
// Distance proximity sensor logic
void sensor(){
 pinMode(sensorPin, OUTPUT);
 digitalWrite(sensorPin, LOW);
 delay(1);
 digitalWrite(sensorPin, HIGH);
 delay(1);
 digitalWrite(sensorPin, LOW);
 pinMode(sensorPin, INPUT);
 distance = pulseIn(sensorPin, HIGH);
 distance = distance / 29.0 / 2.0;
 if(distance > 600){
   distance = 600;
 }
}
// Temperature sensor pin logic
void sensor_temp(){
 float heat = analogRead(tempPin);
 float v = heat * (3300/1024);
 float realT = (v - 500) / 10.0;
 realT = ( (realT * 9.0) / 5.0) + 32.0;
 if(firstActuatorOpen == true || secondActuatorOpen == true){
   realT = realT - 60;
 }
 temp = realT;
}
// Humidity sensor pin logic
void sensor_humidity(){
 humidity = analogRead(humidityPin);
 humidity = (humidity / 1023.0 ) * 5; // humidity ADC voltage converted
 humidity = (5.0-humidity)*10.0/humidity; // humidity converted to match percentage
}
void print_info_monitor(){
 Serial.print("Temperature: ");
 Serial.print(temp);
 Serial.print(" Degrees Farenheit \n");
 Serial.print("Humidity: ");
 Serial.print(humidity);
 Serial.print(" % \n");
 Serial.print("Distance ");
 Serial.print(distance);
 Serial.println(" cm \n");
}
void actuator(){
 bool notComfortable = false;
 Serial.println(estimate_sec);
 if(estimate_sec >= 30) {
   estimate_sec = 0; // reset seconds clock
   digitalWrite(solenoid, LOW); // first actuator reset
   digitalWrite(solenoid2, LOW); // second actuator reset
   firstActuatorOpen = false;
   secondActuatorOpen = false;
 }
 // Determine if room is comfortable at normal temperatures
 if(temp > 60 || humidity > 18) {
   notComfortable = true;
 }
 else if(temp < 58 && humidity < 18) {
   digitalWrite(solenoid2, LOW);
 }
 else{
   notComfortable = false;
 }
 if(notComfortable == true){
   if(distance < 15 && estimate_sec < 10) {
     digitalWrite(solenoid, HIGH);
     firstActuatorOpen = true;
     delay(100);
   }
   else if(distance > 15 && distance < 200 && estimate_sec > 10) {
     digitalWrite(solenoid2, HIGH);
     secondActuatorOpen = true;
     delay(100);
   }
 }
 else{
   if(secondActuatorOpen == true && firstActuatorOpen == true){
      secondActuatorOpen = false; // close part of window
   }
   else if(firstActuatorOpen == true && secondActuatorOpen == false){
     firstActuatorOpen = false; // window fully closed
   }
 }
 delay(1000);
 estimate_sec++;
}

ESP32 Code:
#include <SPI.h>
#include <WiFi.h>
#include "ThingSpeak.h"
#include <ArduinoMqttClient.h>


const char ssid[] = "ECE_Labs";
const char pass[] = "348#ECEWiFi";
WiFiClient client;
MqttClient mqttClient(client);
const char broker[] = "test.mosquitto.org";
int port = 1883;
int status = WL_IDLE_STATUS;     // the Wifi radio's status
unsigned long myChannelNumber = 1981479;
const char* myReadAPIKey = "DG05W3RZOL9HRY6K";
float distance, temp, humidity;
const char topic[] = "final_sensors";


void setup() {
 Serial.begin(9600); // BAUD rate 9600 serial display terminal
 Serial.println("Attempting to connect to WPA network..."); 
 WiFi.mode(WIFI_STA); //Optional
 WiFi.begin(ssid, pass);
 Serial.println("\nConnecting");


 while(WiFi.status() != WL_CONNECTED){
  Serial.print(".");
   delay(100);
 }
 Serial.println("You're connected to the network\n");
 Serial.print("Attempting to connect to the MQTT broker on ESP32: ");
 Serial.println(broker);
//connection to the broker failed
 if (!mqttClient.connect(broker, port)) {
   Serial.print("MQTT connection failed! Error code = ");
   Serial.println(mqttClient.connectError());
   while (1);
 }
  Serial.println("Connected to the MQTT broker on ESP32!\n");
 mqttClient.onMessage(onMqttMessage);
 mqttClient.subscribe(topic);
}


void loop() {
 Serial.println("Reading from Client!...");
 delay(1000);
 mqttClient.poll();
 mqttClient.onMessage(onMqttMessage);


}


void onMqttMessage(int messageSize){
 Serial.print(mqttClient.messageTopic());
 while(mqttClient.available()){
   Serial.print((char)mqttClient.read());
 }
 Serial.println();
}
