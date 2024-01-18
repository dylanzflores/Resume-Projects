# Debugging
wait_time = 0   # Seconds , this is a counter for the duration during GPS fixture

# User Input Libraries
import RPi.GPIO as GPIO # Import Raspberry Pi GPIO library
import pyautogui

GPIO.setmode(GPIO.BCM)

# GPS Libraries
import time
import board
import busio
import logging  # DEBUG messages for location detector
import urllib3  # DEBUG messages for location detector
import math

import adafruit_gps

from geopy.geocoders import Nominatim
from geopy.geocoders import options
from langdetect import detect

# Translator Libraries
import cv2
from google.cloud import storage
from google.cloud import vision
from google.cloud import translate
from google.cloud import translate_v2
import pandas as pd
import io
import os
import time
import sys
import logging    
import traceback
import array
from googletrans import Translator

# Color text
class bcolors:
    DEFAULT = '\033[0m'
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ORANGE = '\033[38;5;214]'

# Google translator : language code names
glanguages = {
    "English": "en",
    "Spanish (Español)": "es",
    "Japanese (日本語)": "ja",
    "Swedish": "sv",
    "French (Français)": "fr",
    "German (Deutsch)": "de",
    "Italian (Italiano)": "it",
    "Chinese (中文)": "zh",
    "Russian (Русский)": "ru",
    "Portuguese (Português)": "pt",
    "Dutch (Nederlands)": "nl",
    "Arabic (العربية)": "ar",
    "Korean (한국어)": "ko",
    "Turkish (Türkçe)": "tr",
    "Greek (Ελληνικά)": "el",
    "Hebrew (עברית)": "he",
    "Polish (Polski)": "pl",
    "Hindi (हिन्दी)": "hi",
    "Thai (ไทย)": "th",
    "Vietnamese (Tiếng Việt)": "vi"
}


# Language code names to full language name via Google Cloud Translate API
language_name = {
    "en": "English",
    "es": "Spanish (Español)",
    "ja": "Japanese (日本語)",
    "sv": "Swedish",
    "fr": "French (Français)",
    "de": "German (Deutsch)",
    "it": "Italian (Italiano)",
    "zh": "Chinese (中文)",
    "ru": "Russian (Русский)",
    "pt": "Portuguese (Português)",
    "nl": "Dutch (Nederlands)",
    "ar": "Arabic (العربية)",
    "ko": "Korean (한국어)",
    "tr": "Turkish (Türkçe)",
    "el": "Greek (Ελληνικά)",
    "he": "Hebrew (עברית)",
    "pl": "Polish (Polski)",
    "hi": "Hindi (हिन्दी)",
    "th": "Thai (ไทย)",
    "vi": "Vietnamese (Tiếng Việt)"
}


# State language mapping
state_lang_map = {
    "Nevada": "English",
    "California": "English",
    "Texas": "English",
    "Washington": "English",
    "New York": "English",
    "Sweden": "Swedish",
    "France": "French",
    "Japan": "Japanese"
}

# Language selection ID (Number to string)
target_language = {
    0: "English",
    1: "Spanish (Español)",
    2: "Japanese (日本語)",
    3: "Swedish",
    4: "French (Français)",
    5: "German (Deutsch)",
    6: "Italian (Italiano)",
    7: "Chinese (中文)",
    8: "Russian (Русский)",
    9: "Portuguese (Português)",
    10: "Dutch (Nederlands)",
    11: "Arabic (العربية)",
    12: "Korean (한국어)",
    13: "Turkish (Türkçe)",
    14: "Greek (Ελληνικά)",
    15: "Hebrew (עברית)",
    16: "Polish (Polski)",
    17: "Hindi (हिन्दी)",
    18: "Thai (ไทย)",
    19: "Vietnamese (Tiếng Việt)"
}

olang = "English" # Output language

logging.getLogger("google").setLevel(logging.WARNING)

# ===================================================================================
# User Input Module
# ===================================================================================
dt = 20     # Direction (pin A)
sw = 17     # Pushbutton
clk = 21    # Clock (pin B)

max_lang = 19

lang = target_language[0] # Default target languge is English

# This is the knob position variable.
count=0

# This will run when the knob changes position.
def click_callback(NULL):
    global count, lang_code
    dir = GPIO.input(dt)

    if (count < 0):
        count = 1
    elif(count > max_lang):
        count = max_lang
    else:   
        if( dir ):
            count +=1 
            # print(bcolors.GREEN + "Spinning CLOCKWISE! " + str(count) + bcolors.DEFAULT)
            time.sleep(0.001)
        else:
            count -= 1
            # print(bcolors.FAIL + "SPINNING COUNTER-CLOCKWISE " + str(count) + bcolors.DEFAULT)
            time.sleep(0.001)
        
        spaces = " " * 20
        
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()

        msg = str(target_language.get(count, "?"))
        lang_code = str(glanguages.get(msg, "en"))

        # Display selection on OLED -------------------------------------------

        disp = OLED_1in51.OLED_1in51()

        # Create blank image for drawing.
        image1 = Image.new('1', (disp.width, disp.height), "WHITE")
        draw = ImageDraw.Draw(image1)
        font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
        font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
        font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
        font4 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)

        #logging.info ("***draw line")
        draw.line([(0,0),(127,0)], fill = 0)
        draw.line([(0,0),(0,63)], fill = 0)
        draw.line([(0,63),(127,63)], fill = 0)
        draw.line([(127,0),(127,63)], fill = 0)

        draw.text((20,15), u'Select your language:', font = font4, fill = 0)
        
        draw.text((30,30), msg+u'', font = font4, fill = 0)

        disp.ShowImage(disp.getbuffer(image1))

        # ---------------------------------------------------------------------

        print(bcolors.HEADER + "  Select your language: " + 
            bcolors.WARNING +  msg + 
            f" [{count}]" +
            spaces, end="\r")

# This is the function that will run when the button is pressed.
def button_down(NULL):
    global pressed
    pressed = True
    spaces = " " * 20
    ss = str(target_language.get(count, "?"))
    if(ss == "?"):
        print("Unknown Language: Turn the knob and try again.")
    else:
        print(bcolors.CYAN + "You have selected: " + 
            bcolors.GREEN + str(target_language[count]) + spaces + 
            bcolors.DEFAULT, end='\n')

        # Display selection on OLED -------------------------------------------

        disp = OLED_1in51.OLED_1in51()

        # Create blank image for drawing.
        image1 = Image.new('1', (disp.width, disp.height), "WHITE")
        draw = ImageDraw.Draw(image1)
        font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
        font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
        font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
        font4 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)

        #logging.info ("***draw line")
        draw.line([(0,0),(127,0)], fill = 0)
        draw.line([(0,0),(0,63)], fill = 0)
        draw.line([(0,63),(127,63)], fill = 0)
        draw.line([(127,0),(127,63)], fill = 0)

        draw.text((20,15), u'You have selected', font = font4, fill = 0)
        
        draw.text((30,30), ss, font = font4, fill = 0)

        disp.ShowImage(disp.getbuffer(image1))

        # ---------------------------------------------------------------------

        pyautogui.press('enter')

def select_lang(NULL):  
    global lang

    sys.stdout.write("\033[?25l")
    sys.stdout.flush()

    # Display selection on OLED -------------------------------------------

    disp = OLED_1in51.OLED_1in51()

    # Create blank image for drawing.
    image1 = Image.new('1', (disp.width, disp.height), "WHITE")
    draw = ImageDraw.Draw(image1)
    font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
    font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
    font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
    font4 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)

    #logging.info ("***draw line")
    draw.line([(0,0),(127,0)], fill = 0)
    draw.line([(0,0),(0,63)], fill = 0)
    draw.line([(0,63),(127,63)], fill = 0)
    draw.line([(127,0),(127,63)], fill = 0)

    draw.text((20,15), u'Select your language:', font = font4, fill = 0)
    
    draw.text((30,30), u'< Turn knob >', font = font4, fill = 0)

    disp.ShowImage(disp.getbuffer(image1))

    # ---------------------------------------------------------------------


    bars = "=" * 80
    print(bars)
    print(bcolors.WARNING)
    print("CHOOSE LANGUAGE: (Use knob to scroll and press button to select your language)\n")
    print(bcolors.DEFAULT)

    # THis just sits here and waits for someone to press enter, everything else happens when events fire off.
    print(bcolors.HEADER + 
        f"  Select your language: {bcolors.WARNING}< Turn knob >", end="\r")
    message = input("")
    print(bcolors.DEFAULT)
   
    lang = target_language[count]

    return lang

GPIO.setwarnings(False) # Ignore warning for now

#This sets the numbering mode to the GPIO number, same as in Linux.

GPIO.setup(sw, GPIO.IN, pull_up_down=GPIO.PUD_UP) # GPIO17 input with pullup high.
GPIO.setup(dt, GPIO.IN, pull_up_down=GPIO.PUD_UP) # GPIO27 input with pullup high.
GPIO.setup(clk, GPIO.IN, pull_up_down=GPIO.PUD_UP) # GPIO22 input with pullup high.

# This sets an event thread that will run the function 'button_down' when a falling edge is detected on GPIO17
GPIO.add_event_detect(sw,GPIO.FALLING,callback=button_down,bouncetime=200)

# This sets and event that runs 'click_callback' when a falling edge (HIGH change to LOW) is detected
# on GPIO22 (knob moved)
GPIO.add_event_detect(clk,GPIO.FALLING,callback=click_callback)

# ===================================================================================
# GPS Module
# ===================================================================================

urllib3.disable_warnings()

logging.getLogger("urllib3").setLevel(logging.WARNING)
logging.getLogger('geopy').setLevel(logging.WARNING)

# Create a serial connection for the GPS connection using default speed and
# a slightly higher timeout (GPS modules typically update once a second).
# These are the defaults you should use for the GPS FeatherWing.
# For other boards set RX = GPS module TX, and TX = GPS module RX pins.
# uart = busio.UART(board.TX, board.RX, baudrate=9600, timeout=10)

# for a computer, use the pyserial library for uart access
import serial
uart = serial.Serial("/dev/ttyUSB0", baudrate=9600, timeout=10)

# If using I2C, we'll create an I2C interface to talk to using default pins
# i2c = board.I2C()  # uses board.SCL and board.SDA
# i2c = board.STEMMA_I2C()  # For using the built-in STEMMA QT connector on a microcontroller

# Create a GPS module instance.
gps = adafruit_gps.GPS(uart, debug=False)  # Use UART/pyserial
# gps = adafruit_gps.GPS_GtopI2C(i2c, debug=False)  # Use I2C interface

# Initialize the GPS module by changing what data it sends and at what rate.
# These are NMEA extensions for PMTK_314_SET_NMEA_OUTPUT and
# PMTK_220_SET_NMEA_UPDATERATE but you can send anything from here to adjust
# the GPS module behavior:
#   https://cdn-shop.adafruit.com/datasheets/PMTK_A11.pdf

# Turn on the basic GGA and RMC info (what you typically want)
# gps.send_command(b"PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
# Turn on just minimum info (RMC only, location):
gps.send_command(b'PMTK314,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0')
# Turn off everything:
# gps.send_command(b'PMTK314,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0')
# Turn on everything (not all of it is parsed!)
# gps.send_command(b'PMTK314,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0')

# Set update rate to once a second (1hz) which is what you typically want.
gps.send_command(b"PMTK220,1000")
# Or decrease to once every two seconds by doubling the millisecond value.
# Be sure to also increase your UART timeout above!
# gps.send_command(b'PMTK220,2000')
# You can also speed up the rate, but don't go too fast or else you can lose
# data during parsing.  This would be twice a second (2hz, 500ms delay):
# gps.send_command(b'PMTK220,500')

#!/usr/bin/python
# -*- coding:utf-8 -*-

import sys
import os
import pandas as pd

picdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'pic')
libdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'lib')
if os.path.exists(libdir):
    sys.path.append(libdir)

import logging    
import time
import traceback
from waveshare_OLED import OLED_1in51
from PIL import Image,ImageDraw,ImageFont
logging.basicConfig(level=logging.DEBUG)

try:
    disp = OLED_1in51.OLED_1in51()

    logging.info("\rInitializing: 1.51inch OLED ")
    # Initialize library.
    disp.Init()
    # Clear display.
    logging.info("Clearing display")
    disp.clear()

    # Create blank image for drawing.
    image1 = Image.new('1', (disp.width, disp.height), "WHITE")
    draw = ImageDraw.Draw(image1)
    font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
    font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
    # logging.info ("***draw line")
    draw.line([(0,0),(127,0)], fill = 0)
    draw.line([(0,0),(0,63)], fill = 0)
    draw.line([(0,63),(127,63)], fill = 0)
    draw.line([(127,0),(127,63)], fill = 0)
    
    draw.text((24,28), u'. . . Starting . . .', font = font1, fill = 0)

    disp.ShowImage(disp.getbuffer(image1))
    time.sleep(3)
    disp.clear()

except IOError as e:
    logging.info(e)
    
except KeyboardInterrupt:    
    logging.info("ctrl + c:")
    OLED_1in51.config.module_exit()
    exit()

show_location = 1
prompt_user_select = 0

# Main loop runs forever printing the location, etc. every second.
last_print = time.monotonic()
while True:
    # Make sure to call gps.update() every loop iteration and at least twice
    # as fast as data comes from the GPS unit (usually every second).
    # This returns a bool that's true if it parsed new data (you can ignore it
    # though if you don't care and instead look at the has_fix property).
    gps.update()
    # Every second print out current location details if there's a fix.
    current = time.monotonic()
    if current - last_print >= 1.0:
        last_print = current
        if not gps.has_fix:
            # Try again if we don't have a fix yet.
            print( + ": Awaiting Fix...")

            disp = OLED_1in51.OLED_1in51()

            # Create blank image for drawing.
            image1 = Image.new('1', (disp.width, disp.height), "WHITE")
            draw = ImageDraw.Draw(image1)
            font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)

            #logging.info ("***draw line")
            draw.line([(0,0),(127,0)], fill = 0)
            draw.line([(0,0),(0,63)], fill = 0)
            draw.line([(0,63),(127,63)], fill = 0)
            draw.line([(127,0),(127,63)], fill = 0)
            
            draw.text((24,10), u'...Awaiting Fix...', font = font1, fill = 0)
            draw.text((10,30), u'(This will take a bit.)', font = font3, fill = 0)

            disp.ShowImage(disp.getbuffer(image1))

            continue

        # Driving detection has first priority
        if gps.speed_knots*1.151 > 15.00:
            print("Warning: Driving detected. Please take off the device immediately.")

            disp = OLED_1in51.OLED_1in51()

            # Create blank image for drawing.
            image1 = Image.new('1', (disp.width, disp.height), "WHITE")
            draw = ImageDraw.Draw(image1)
            font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            font4 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)

            #logging.info ("***draw line")
            draw.line([(0,0),(127,0)], fill = 0)
            draw.line([(0,0),(0,63)], fill = 0)
            draw.line([(0,63),(127,63)], fill = 0)
            draw.line([(127,0),(127,63)], fill = 0)
            spf = "{:.2f}".format(gps.speed_knots*1.151)
            sp = str(spf)

            draw.text((5,10), u'WARNING: ', font = font2, fill = 0)
            draw.text((65,10), sp + u' MPH', font = font4, fill = 0)
            draw.text((10,24), u'(Driving detected!)', font = font1, fill = 0)
            draw.text((10,38), u'Device disabled.', font = font3, fill = 0)

            disp.ShowImage(disp.getbuffer(image1))

            continue
        # ====================================================================================
        # We have a fix! (gps.has_fix is true)
        # Print out details about the fix like location, date, etc.
        print("=" * 80)  # Print a separator line.
        '''print(
            bcolors.HEADER + "Fix timestamp: {}/{}/{} {:02}:{:02}:{:02}".format(
                gps.timestamp_utc.tm_mon,  # Grab parts of the time from the
                gps.timestamp_utc.tm_mday,  # struct_time object that holds
                gps.timestamp_utc.tm_year,  # the fix time.  Note you might
                gps.timestamp_utc.tm_hour,  # not get all data like year, day,
                gps.timestamp_utc.tm_min,  # month!
                gps.timestamp_utc.tm_sec,
            ) + bcolors.DEFAULT
        )
        print(bcolors.CYAN+"Latitude: {0:.6f} degrees".format(gps.latitude))
        print("Longitude: {0:.6f} degrees".format(gps.longitude))
        print(
            "Precise Latitude: {:2.4f}{:2.4f} degrees".format(
                gps.latitude_degrees, gps.latitude_minutes
            )
        )
        print(
            "Precise Longitude: {:2.4f}{:2.4f} degrees".format(
                gps.longitude_degrees, gps.longitude_minutes
            ) + bcolors.DEFAULT
        )
        '''
        #print("Fix quality: {}".format(gps.fix_quality))

        # Detect language based on lat/long coordinates
        def get_city_and_state(latitude, longitude):
            geolocator = Nominatim(user_agent="my-gps")
            location = geolocator.reverse(f"{latitude}, {longitude}", exactly_one=True)
            
            #print("Location: ", location)

            if location and 'address' in location.raw:
                address = location.raw['address']
                city = address.get('city', '')
                #print("City: ", city)
                state = address.get('state', '')
                #print("State: ", state)
                return city, state
            
            return None, None

        city, state = get_city_and_state(gps.latitude_degrees, gps.longitude_degrees)

        olang = state_lang_map.get(state, "Unknown")
        
        if(show_location == 1 and prompt_user_select == 0):
            
            if city and state:
                print(f"{bcolors.GREEN}You are in {state} | {bcolors.CYAN}Default language set to: {olang}{bcolors.DEFAULT}")
            else:
                print(f"{bcolors.WARNING}State information not available for the given coordinates.{bcolors.DEFAULT}")

        
            disp = OLED_1in51.OLED_1in51()

            # Create blank image for drawing.
            image1 = Image.new('1', (disp.width, disp.height), "WHITE")
            draw = ImageDraw.Draw(image1)
            font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
            font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
            font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
            font4 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)

            #logging.info ("***draw line")
            draw.line([(0,0),(127,0)], fill = 0)
            draw.line([(0,0),(0,63)], fill = 0)
            draw.line([(0,63),(127,63)], fill = 0)
            draw.line([(127,0),(127,63)], fill = 0)

            draw.text((10,10), u'Welcome to:', font = font1, fill = 0)
            draw.text((80,10), state + u'', font = font2, fill = 0)
            draw.text((10,30), u'Area language: ', font = font3, fill = 0)
            draw.text((80,30), olang + u'', font = font4, fill = 0)

            disp.ShowImage(disp.getbuffer(image1))

            show_location = 0
            prompt_user_select = 1

            time.sleep(2)

            disp.clear()

            continue

        if  show_location == 0 and prompt_user_select == 1:

            # Prompt for user input
            select_lang(0)

            prompt_user_select = 0

            time.sleep(2)

            disp.clear()

        else:
            break
        
        # ====================================================================================

        
        # Some attributes beyond latitude, longitude and timestamp are optional
        # and might not be present.  Check if they're None before trying to use!
        '''if gps.satellites is not None:
            print("# satellites: {}".format(gps.satellites))
            break

        #if gps.altitude_m is not None:
        #   print("Altitude: {} meters".format(gps.altitude_m))
        
        
        if gps.speed_knots is not None:
            print("Speed: {:.2f} MPH".format(gps.speed_knots*1.151))
        
            disp = OLED_1in51.OLED_1in51()

            # Create blank image for drawing.
            image1 = Image.new('1', (disp.width, disp.height), "WHITE")
            draw = ImageDraw.Draw(image1)
            font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 12)
            #logging.info ("***draw line")
            draw.line([(0,0),(127,0)], fill = 0)
            draw.line([(0,0),(0,63)], fill = 0)
            draw.line([(0,63),(127,63)], fill = 0)
            draw.line([(127,0),(127,63)], fill = 0)
            spf = "{:.2f}".format(gps.speed_knots*1.151)
            sp = str(spf)
            draw.text((10,14), u'Speed: ', font = font2, fill = 0)
            draw.text((10,28), sp + u' MPH', font = font1, fill = 0)

            disp.ShowImage(disp.getbuffer(image1))
        '''   

        #if gps.track_angle_deg is not None:
         #   print("Track angle: {} degrees".format(gps.track_angle_deg))
        #if gps.horizontal_dilution is not None:
        #    print("Horizontal dilution: {}".format(gps.horizontal_dilution))
        #if gps.height_geoid is not None:
            #print("Height geoid: {} meters".format(gps.height_geoid))


# ===================================================================================
# Translator Module
# ===================================================================================

# Display on OLED ----------------------------------------------------

disp = OLED_1in51.OLED_1in51()

# Create blank image for drawing.
image1 = Image.new('1', (disp.width, disp.height), "WHITE")
draw = ImageDraw.Draw(image1)
font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
font3 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
font4 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)

#logging.info ("***draw line")
draw.line([(0,0),(127,0)], fill = 0)
draw.line([(0,0),(0,63)], fill = 0)
draw.line([(0,63),(127,63)], fill = 0)
draw.line([(127,0),(127,63)], fill = 0)

draw.text((15,15), u'...Loading Translator...', font = font4, fill = 0)

disp.ShowImage(disp.getbuffer(image1))

# ---------------------------------------------------------------------

# initialize the camera
cam = cv2.VideoCapture(0)

image1 = Image.new('1', (disp.width, disp.height), "WHITE")
draw = ImageDraw.Draw(image1)
draw.line([(0,0),(127,0)], fill = 0)
draw.line([(0,0),(0,63)], fill = 0)
draw.line([(0,63),(127,63)], fill = 0)
draw.line([(127,0),(127,63)], fill = 0)

draw.text((15,15), u'HOLD STILL...', font = font4, fill = 0)

disp.ShowImage(disp.getbuffer(image1))
time.sleep(3)
ret, image = cam.read()
if ret:
    cv2.imshow('img', image)
    cv2.destroyWindow('img')
    cv2.waitKey(0)
    cv2.imwrite('/home/dylan/Senior_Design/img.jpg', image)

cam.release()
print("Image captured...\n")

# raspberry pi target directory for file send to bucket
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'/home/dylan/Senior_Design/sdtesting-381922-e0eaf737e0c8.json'
# Storage client instance
storage_client = storage.Client()
#translation
translate_client = translate_v2.Client()

# Get a reference to the bucket
bucket = storage_client.bucket('imageprocessing')

image1 = Image.new('1', (disp.width, disp.height), "WHITE")
draw = ImageDraw.Draw(image1)
draw.line([(0,0),(127,0)], fill = 0)
draw.line([(0,0),(0,63)], fill = 0)
draw.line([(0,63),(127,63)], fill = 0)
draw.line([(127,0),(127,63)], fill = 0)

draw.text((15,15), u'Processing...', font = font4, fill = 0)

disp.ShowImage(disp.getbuffer(image1))

# Upload a file to the bucket
blob = bucket.blob('img.jpg')
blob.upload_from_filename('/home/dylan/Senior_Design/img.jpg')
print("Image in bucket.......\n")

#set the image file to be sent to imageprocessing bucket
client = vision.ImageAnnotatorClient()
image = vision.Image()
image_URL = 'img.jpg'
image.source.image_uri = 'gs://imageprocessing/' + image_URL

#get image text from images
response = client.text_detection(image=image)
texts = response.text_annotations
df = pd.DataFrame(columns=['locale', 'description'])
print("Processing Translation: ")

try:

    image1 = Image.new('1', (disp.width, disp.height), "WHITE")
    draw = ImageDraw.Draw(image1)
    draw.line([(0,0),(127,0)], fill = 0)
    draw.line([(0,0),(0,63)], fill = 0)
    draw.line([(0,63),(127,63)], fill = 0)
    draw.line([(127,0),(127,63)], fill = 0)

    draw.text((15,15), u'Translating...', font = font4, fill = 0)

    disp.ShowImage(disp.getbuffer(image1))

    for text in texts:
        df = df._append(
            dict(
            locale = text.locale, 
            description = text.description
        ),
        ignore_index = True
    )
        #get text to translate
    text = df['description'][0]
    word = df['description']

    print("Image Text gathered....\n")
    print(df['locale'][0])
    print(text)

except:
    # ---------------------------------------------------------------------------------------
    # No words detected
    # ---------------------------------------------------------------------------------------
    error = "No text detected"
    print(error + '\n')

    picdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'pic')
    libdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'lib')
    if os.path.exists(libdir):
        sys.path.append(libdir)
    logging.basicConfig(level=logging.DEBUG)
    from waveshare_OLED import OLED_1in51
    from PIL import Image,ImageDraw,ImageFont
    logging.basicConfig(level=logging.DEBUG)

    disp = OLED_1in51.OLED_1in51()
    # Initialize library.
    disp.Init()
    # Clear display.
    disp.clear()
    # Create blank image for drawing.
    image1 = Image.new('1', (disp.width, disp.height), "WHITE")
    draw = ImageDraw.Draw(image1)
    font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
    draw.line([(0,0),(127,0)], fill = 0)
    draw.line([(0,0),(0,63)], fill = 0)
    draw.line([(0,63),(127,63)], fill = 0)
    draw.line([(127,0),(127,63)], fill = 0)
    draw = ImageDraw.Draw(image1)
    draw.text((7,20), format(error), font = font1, fill = 0)        
    disp.ShowImage(disp.getbuffer(image1))
    time.sleep(3)
    disp.clear()
    exit()
  # ---------------------------------------------------------------------------------------
  # Translating
  # ---------------------------------------------------------------------------------------

name_code = str(df['locale'][0])

#set output language here
target = lang_code
a = language_name.get(name_code, "English")

if a != olang:
    print('\n'+bcolors.WARNING + a + " detected!")
    print(bcolors.DEFAULT)

    image1 = Image.new('1', (disp.width, disp.height), "WHITE")
    draw = ImageDraw.Draw(image1)
    draw.line([(0,0),(127,0)], fill = 0)
    draw.line([(0,0),(0,63)], fill = 0)
    draw.line([(0,63),(127,63)], fill = 0)
    draw.line([(127,0),(127,63)], fill = 0)

    draw.text((20,25), a, font = font4, fill = 0)
    draw.text((20,35), u'detected!', font = font4, fill = 0)

    disp.ShowImage(disp.getbuffer(image1))

    time.sleep(1.5)

#get output translation
output = translate_client.translate(text, target_language = target)

#print check translation
print(f"{bcolors.WARNING}\nTranslation:\n{bcolors.GREEN}")
print(format(output["translatedText"]))
print(bcolors.DEFAULT)

picdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'pic')
libdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'lib')
if os.path.exists(libdir):
    sys.path.append(libdir)
logging.basicConfig(level=logging.DEBUG)
from waveshare_OLED import OLED_1in51
from PIL import Image,ImageDraw,ImageFont
logging.basicConfig(level=logging.DEBUG)
disp = OLED_1in51.OLED_1in51()

try:
    # Initialize library.
    disp.Init()
    # Clear display.
    disp.clear() #draw.text((10,14), u'Longer Senstence 2 ', font = font2, fill = 0)
    #draw.text((10,28), u'Longer Senstence 3 ', font = font1, fill = 0)
    def disp_OLED(d, w, m):
    # Create blank image for drawing.
        image1 = Image.new('1', (disp.width, disp.height), "WHITE")
        draw = ImageDraw.Draw(image1)
        font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 15)
        draw.line([(0,0),(127,0)], fill = 0)
        draw.line([(0,0),(0,63)], fill = 0)
        draw.line([(0,63),(127,63)], fill = 0)
        draw.line([(127,0),(127,63)], fill = 0)
         #image1 = image1.rotate(180) 
        t1 = w
        draw = ImageDraw.Draw(image1)
        draw.text((m,20), t1, font = font1, fill = 0)
        disp.ShowImage(disp.getbuffer(image1))
        #disp.clear()
    if(len(output["translatedText"]) < 20) :
        translatedText = format(output["translatedText"])
        result = translatedText.replace('\n',' ')
        disp_OLED(disp, result, 7)
        time.sleep(5)
    else :
        print("Translation to OLED: \n")
        for x in range (0, (-len(output["translatedText"]) * 7), -10):
            translatedText = format(output["translatedText"])
            result = translatedText.replace('\n',' ')
            disp_OLED(disp, result, x)
    disp.clear()

except IOError as e:
    logging.info(e)
    
except KeyboardInterrupt:    
    logging.info("ctrl + c:")
    OLED_1in51.config.module_exit()
    exit()

def display_image_set():
    # Create blank image for drawing.
    image1 = Image.new('1', (disp.width, disp.height), "WHITE")
    draw = ImageDraw.Draw(image1)
    font1 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 10)
    font2 = ImageFont.truetype(os.path.join(picdir, 'Font.ttc'), 8)
    draw.line([(0,0),(127,0)], fill = 0)
    draw.line([(0,0),(0,63)], fill = 0)
    draw.line([(0,63),(127,63)], fill = 0)
    draw.line([(127,0),(127,63)], fill = 0)

