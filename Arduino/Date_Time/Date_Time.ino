//include necesery libraries
//libraries are downloaded from the github.
#include <NTPClient.h>    //NTPClient library is used to get the date and time from the internet.

#include "FirebaseESP8266.h"    //FirebaseESP8266 is firebase database libabry for esp8266(NodeMCU).

#include <WiFiUdp.h>    //The below libraries in the line 6,7,8,9,10 are used for wifi connectivity
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <WiFiManager.h> 
#include <ESP8266HTTPClient.h>

#include "DHT.h"    //DHT.h library is used to get the data from the DHT11 sensor(temperature and humidity). 

#define DHTTYPE DHT11   //mention type of DHT sensor, here we are using DHT11 (Note: There other sensors like dht22 in the market)

//firebase host and auth you will get it from the firebase database consol.
#define FIREBASE_HOST "cproject2-e2606-default-rtdb.firebaseio.com"   //Firebase_host is the path of the firebase database
#define FIREBASE_AUTH "ocu8zF50A5NW9YZbYq1wZFTgbcJPD5MrND1R7iXX"      //firebase authentication key 

FirebaseData firebaseData;    //create FirebaseData object

const long utcOffsetInSeconds = 19800;

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", utcOffsetInSeconds);   //initializing date and time server.

//variable used
String date_time;
int index_date; 
String currentDate;
String currentTime;

//this is your user id this one you will be required when you are going to login to the app
String user = "user123";

//sensor pins
int gasPin = A0;
int firePin = D3;
int dhtPin = D1;
int relayPin = D2;
int buzzerPin = D5;


DHT dht(dhtPin, DHTTYPE); //initialize dht11 sensor

//Note: not every sensor need to be initialized by creating objects.

int gasData;
int fireData;

//IP ADDRESS: 192.168.4.1
//there are 2 parts in every arduinoC program, that is setup and loop
//setup is used to initialization and loop is used to execute the code in a loop
//loop executes untill there there is power to the micro controller.

void setup(){
  //Serial.begin is used to display some output in the serial monitor screen
  //115200 is the baud rate
  Serial.begin(115200);

  //mentioning the pinmode of the sensor
  //if the sesor gives input to the microcontroller then it should be mention as INPUT as below
  //if the sesor takes output to the microcontroller then it should be mention as OUTPUT as below

  pinMode(gasPin, INPUT);     //gas sensor(MQ2 sensor) gives input.
  pinMode(firePin, INPUT);    //fire sensor gives input.
  pinMode(relayPin, OUTPUT);  //relay is used to turn on the sprinkler it takes the input and gives output.
  pinMode(buzzerPin, OUTPUT); //buzzer is used to alert the user by making sound, and it takes input and gives output.
  
  dht.begin();    //begin the dht11 sensor.

  digitalWrite(relayPin,HIGH);  //set relay pins initial state
  
  connectWifiManager();   //wifi connectivity function go to line number 147
  connectToFirebase();    //firebase connectivity function go to line number 154
}


//here loop starts
void loop() {
  
  if (WiFi.status() == WL_CONNECTED){   // check whether the microcontroller connected to the wifi or not. If it is connected to the wifi execute the below statement.
    Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/Profile/Online", "1");   //set microcontroller to online in firebase to notifi in the app whether the microcontroller connected to the wifi or not

    Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Sprinkler/Status");    //check sprinkler turned on or off in the app
    if(firebaseData.stringData() == "1"){   
      digitalWrite(relayPin,LOW);   //if it is on turn on relay
    }else{
      digitalWrite(relayPin,HIGH);  //else turn off the relay.
    }
    
    Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Controller/Gas");    //check gas sensor is turned on or not
    if(firebaseData.stringData() == "1"){   //if it is turned on execute below statement
      gasData = gasDetection();   //gasDetection() is a function to get the gas sensor data, go to line number 183, here the gas data is stored in gasData variable
      Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/LiveData/Gas", String(gasData));   //set the gasData to the firebase
      if(gasData >= 450){   //if the gasData is crossed 450 it means that gas leackage is detected.
        playBuzzer();   //playBuzzer() is a function to play the buzzed, go to line number 235
        getDateTime();  //getDateTime() is a function to fetch the current date and time, go to line number 167
        String key = currentDate + currentTime;   //key is generated to to store the unique value in the firebase. It is the combination of current date and time
        key.replace("-","");    //replays - from key variable to empty space
        key.replace(":","");    //replays : from key variable to empty space
        
        Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/History/Gas/" + key + "/Date", currentDate);       //set current date to firebase
        Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/History/Gas/" + key + "/Time", currentTime);       //set current time to firebase
        Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/History/Gas/" + key + "/Value", String(gasData));  //set the gasData value to firebase
  
        setNotification("Gas");   //setNotification() funtion is used to set the notification in the firebase, go to line number 240
        
        String message = "Gas leakage detected on " + currentDate + ", please be alert. - GASFIR";
        message.replace(" ","%20");
        sendSMS(message);    //sendSms() is a function used to send the sms to the mobile number, go too line number 
      }
    }else{
      Serial.println("Gas Sensor turned off");    // if the gas sensor is turned off display the message in serial monitor.
    }
  
    Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Controller/Fire");   //check fire sensor is turned on or not
    if(firebaseData.stringData() == "1"){   //if it is turned on execute below statement
      fireData = fireDetection();   //fireDetection() is a function to get the fire sensor data, go to line number 189, here the gas data is stored in fireData variable
      Serial.println(fireData);     //diaplay firedata in serial monitor
      if(fireData == 0){    //if the fireData is equal to 0 it means that fire is detected.
        playBuzzer();   //playBuzzer() is a function to play the buzzed, go to line number 235
        getDateTime();  //getDateTime() is a function to fetch the current date and time, go to line number 167
        String key = currentDate + currentTime;   //key is generated to to store the unique value in the firebase. It is the combination of current date and time
        key.replace("-","");    //replays - from key variable to empty space
        key.replace(":","");    //replays : from key variable to empty space
        
        Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/History/Fire/" + key + "/Date", currentDate);    //set current date to firebase
        Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/History/Fire/" + key + "/Time", currentTime);    //set current time to firebase
        
        turnOnSprinkler();    //turnOnSprinkler(() is a function used to turn on the sprinkler, go to line number 223
        setNotification("Fire");    //setNotification() funtion is used to set the notification in the firebase, go to line number 240

        String message = "Fire detected on " + currentDate + ", please be alert. - GASFIREDETECTION";
        message.replace(" ","%20");
        sendSMS(message);    //sendSms() is a function used to send the sms to the mobile number, go too line number 
      }
    }else{
      Serial.println("Fire Sensor turned off");   // if the fire sensor is turned off display the message in serial monitor.
    }
  
    detecttempHumi();   //detect temperature and humidity, this is a function used to detect the temperature and humidity, go to line number 194
    delay(1000);        //delay mean it makes microcontroller for given time, here it 1000 mili second means 1 secon.
    
  }
  
}


//wifi connectivity function
void connectWifiManager(){    
  WiFiManager wifiManager;
  wifiManager.resetSettings();
  wifiManager.autoConnect("Alert WiFi");
  Serial.println("connected ");
}

//firebase connectivity function
void connectToFirebase(){
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH); 
  
  Firebase.reconnectWiFi(true);
  Firebase.setMaxRetry(firebaseData, 3);
  Firebase.setMaxErrorQueue(firebaseData, 30);  
  Firebase.enableClassicRequest(firebaseData, true); 
  firebaseData.setBSSLBufferSize(1024, 1024);
  firebaseData.setResponseSize(1024);
}

//get current date and time function.
void getDateTime(){
  while(!timeClient.update()) {
    timeClient.forceUpdate();   //if the date and time is not updated update the date and time
  }

  date_time = timeClient.getFormattedDate();
  index_date = date_time.indexOf("T");
  
  currentDate = date_time.substring(0, index_date);
  currentTime = timeClient.getFormattedTime();
  
  Serial.println(currentDate);
  Serial.println(currentTime);
}

//get gas sensor data function
int gasDetection(){
  return analogRead(gasPin);
}


//get fire sensor data function
int fireDetection(){
  return digitalRead(firePin);
}

//get temperature and humidity function
void detecttempHumi(){
  
  float humi = dht.readHumidity();    //get humidity from dht11 sensor
  float temp = dht.readTemperature(); //get temperature from dht11 sensor

  if(temp >= 0){
    Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Controller/Temp");   //check temperature is turned on or off
    if(firebaseData.stringData() == "1"){   //if it is turned on execute below statement
      Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/LiveData/Temp", String(temp));   //set temperature in firebase
    }else{    //if the sensor turned off diaply the message in serial monitor
      Serial.println("Temperature turned off");
    }
  }else{    //if the temperature data is null diaplay it in serial monitor.
    Serial.println("temp Nan");
  }

  if(humi >= 0){
    Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Controller/Humi");   //check humidity is turned on or off
    if(firebaseData.stringData() == "1"){   //if it is turned on execute below statement
      Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/LiveData/Humi", String(humi));   //set humidity in firebase
    }else{    //if the sensor turned off diaply the message in serial monitor
      Serial.println("Humidity turned off");
    } 
  }else{    //if the temperature data is null diaplay it in serial monitor.
    Serial.println("humi Nan");
  }
}

//function to turn on or off the sprinkler
void turnOnSprinkler(){
  Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Controller/Sprinkler");    //check sprinkler is turned on or off
  if(firebaseData.stringData() == "1"){   //if it is turned on execute below statement
    digitalWrite(relayPin,LOW);   //if the sprinkler turned on enable the relay
    delay(5000);                  //wait for 5 second
    digitalWrite(relayPin,HIGH);  //disable the relay
  }else{    //if the sensor is turned off display the message in serial monitor
    Serial.println("Sprinkler turned off");
  }
}

//function to play the buzzer
void playBuzzer(){
  tone(buzzerPin, 1000, 2000);    //statement to play the buzzer, here 1000 is sound frequency and 2000 is time (2 second)
}

//function to set the notification
void setNotification(String from){
  Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/Detection/" + from + "/Detected", "1");
  Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/Detection/" + from + "/Date", currentDate);
  Firebase.setString(firebaseData, "FireGasDetection/User/" + user + "/Detection/" + from + "/Time", currentTime);
}


//send message to the mobile number
void sendSMS(String message){
  
  Serial.println("Sending SMS");

  Firebase.getString(firebaseData, "FireGasDetection/User/" + user + "/Sms/Number");    //take the mobile number from the firebase
  String number = firebaseData.stringData();
  
  String host = "http://sms.bixtel.com/api/mt/SendSMS?APIKey=NDCTcGTRkEqUqqqVVjM5nQ&senderid=GASFIR&channel=2&DCS=0&flashsms=0&number=91" + number + "&text=" + message + "&route=1";   //url to send the message
  HTTPClient http;  //library used to execute the url
  http.begin(host); //execute the url
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  
  int httpCode = http.GET();    //return code 
  String payload = http.getString();    //return message

  Serial.println("HTTP CODE: " + String(httpCode));
  Serial.println("PAYLOAD: " + payload);

  http.end();   //after sending sms close the http connection
}
