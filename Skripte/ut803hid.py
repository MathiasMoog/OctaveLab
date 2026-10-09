#! /bin/env python3
""" Talk to a UNI-T UT803 bench multimeter via USB HID interface.

Years ago I found some hints on Hendrik Hsftmann's web page, https://heha.fwh.is/ including a rough documentation of the 
HID Chicp Hotek HE2325U USB to UART bridge, which is used in the UT803. 

This implementation is based on the hid project for python, see https://pypi.org/project/hid/

- Windows

https://github.com/libusb/hidapi/releases

- Linux 

Regeln für die hidraw Geräte anpassen, siehe https://gitlab.com/CalcProgrammer1/OpenRGB/-/work_items/1985

    sudo nano /etc/udev/rules.d/51-usb-device.rules

Folgende Zeile hinzu

    SUBSYSTEMS=="hidraw", GROUP="plugdev", MODE="666"

Damm die Regeln neu laden

    sudo udevadm control --reload-rules

Jetzt wird noch die aktuelle hid implementierung benötigt. Die gibt es nur über pip. 
Die python3-hid und python3-hidapi sind veraltet und nutzen ein gänzlich anderes Interface zu dem es im Netz kaum noch Doku gibt.

    python3 -m venv /home/mathias/Software/Lab
    source /home/mathias/Software/Lab/bin/activate
    pip install hid pandas

Die benötigte libusb (libusb-1.0-0-dev,libhidapi-libusb0) ist bei mir schon vorinstalliert.

Aus UT 803.log

 *  Byte			6	5	4	3	2	1	0
 * [0]	Bereich		0	1	1	0	====siehe unten===
 * [1]	1. Ziffer	0	1	1	===========Ziffer=========
 * [2]	2. Ziffer	0	1	1	===========Ziffer=========
 * [3]	3. Ziffer	0	1	1	===========Ziffer=========
 * [4]	4. Ziffer	0	1	1	===========Ziffer=========
 * [5]	Schalterst.	0	1	1	========siehe unten=======
 * [6]	Info		0	1	1	°C	NEG	LoBat	OVL	// °C-Bit ist immer gesetzt außer bei °F
 * [7]	Info2		0	1	1	HOLD	MAX	MIN	0	// Rel vermutlich geplant, aber keine Taste vorhanden
 * [8]	Kopplung	0	1	1	DC	AC	AUTO	0	// DC und AC zwar kombiniert am Gerät, jedoch keine Übertragung!
 * [9]	'\r'		0	0	0	1	1	0	1
 * [10]	'\n'		0	0	0	1	0	1	0

 * LONIBBLE(Byte[5]):	B	3	6	2	D	F	9	4	4	E       5   
 * Bereich (Byte[0]):	V	Ohm	F	Hz	µA	mA	A	°C	°F	hFE    Diode
 *          '0'		6.000	600.0	6.000n	6000	600.0µ	60.00m	10.00	1000	1800	6000
 *          '1'		60.00	6.000k	60.00n	60.00k	6000µ	600.0m	-	-	-	-
 *          '2'		600.0	60.00k	600.0n	600.0k	-	-	-	-	-	-
 *          '3'		1000	600.0k	6.000µ	6.000M	-	-	-	-	-	-
 *          '4'		600.0m	6.000M	60.00µ	60.00M	-	-	-	-	-	-
 *          '5'		-	60.00M	600.0µ	-	-	-	-	-	-	-
 *          '6'		-	-	6.000m	-	-	-	-	-	-	-
 *          '7'		-	-	-	-	-	-	-	-	-	-
 * 
 * Schalterstellung (Byte[5]) und etwaige Abtastrate:
 * 	'1'	Diode	10 Sa/s
 * 	'2'	Hz	2 Sa/s
 * 	'3'	Ohm	2 Sa/s
 * 	'4'	°F/°C	2 Sa/s
 * 	'5'	Pieps	10 Sa/s
 * 	'6'	F	im Bereich 6 mF sehr niedrige Rate, etwa 0,2 Sa/s {5 s/Sa}
 * 	'9'	A	3 Sa/s
 * 	';'(3B)	V	2 Sa/s
 * 	'='(3D)	µA	3 Sa/s
 * 	'>'(3E)	hFE	2 Sa/s
 * 	'?'(3F)	mA	3 Sa/s
 */

 Es gibt einen kleinen Puffer. Doppelt lesen sonst ggf. alter Wert.

 Umsetzung in Java Elektro/Programme/DMM/DMM/src/dmm/UT803decode.java

 Eine Umsetzung mit python3-hidapi und der alten hidapi-cffi ist mir nicht gelungen, selbst als root konnte ich wer von dem 
 Geräte lese noch schreiben. Damit sind das UT803 und das UT8800 incompatibel.
"""

import hid
from pandas import NA


class ut803hid:
    "Device class for uni-t ut803 bench multimeters"

    # Einheiten, auf Index aufpassen!
    utEinheit = [ "", "", "Hz", "Ohm", "°C", "°C", "F", "", "", "A", "", "V", "", "A", "hFE", "A"]
    # Umrechenfaktoren
    #NA=float('nan')
    utFaktor = [
    [NA, NA, 1e0, 0.1e0, 1e0, 0.1e0, 0.001e-9, NA, NA, 0.01e0, NA, 0.001e0, NA, 0.1e-6, 1, 0.01e-3],
    [NA, NA, 0.01e3, 1e0, NA, 1e0, 0.01e-9, NA, NA, NA, NA, 0.01e0, NA, 1e-6, NA, 0.1e-3],
    [NA, NA, 0.1e3, 0.01e3, NA, 0.01e3, 0.1e-9, NA, NA, NA, NA, 0.1e0, NA, NA, NA, NA],
    [NA, NA, 1e3, 0.1e3, NA, 0.1e3, 0.001e-6, NA, NA, NA, NA, 1e0, NA, NA, NA, NA],
    [NA, NA, 0.01e6, 1e3, NA, 1e3, 0.01e-6, NA, NA, NA, NA, 0.1e-3, NA, NA, NA, NA],
    [NA, NA, NA, 0.01e6, NA, 0.01e6, 0.1e-6, NA, NA, NA, NA, NA, NA, NA, NA, NA],
    [NA, NA, NA, NA, NA, NA, 0.1e-6, NA, NA, NA, NA, NA, NA, NA, NA, NA],
    [NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA]]


    def __init__(self):
        self.dev = None

    def __del__(self):
        self.disconnect()

    # OctaveLab Like Interface

    def isConnected(self):
        """Check if connected to multimeter"""
        if self.dev:
          return True
        return False
        
    def connect(self):
        """ Try to connect to multimeter.
          Read ID after connection
        """
        if self.isConnected():
            print("Allready connectd")
            return
        # Device öffnen
        self.dev = hid.Device(6790,57352)
        # Konfigurieren, 19200 Baud = 0x4B00, Rest wie in HoitexHE2325U.pdf
        fr = bytes.fromhex('00 00 4B 00 00 03')
        #print(fr)
        self.dev.send_feature_report(fr)


    def disconnect(self):
        """ Disconnect from multimeter."""
        if (self.isConnected()):
            try:
                self.dev.close()
            except:
                pass 
            self.dev = None

    def getValue(self):
        """ Get the first value / unit pair from serial buffer.
          return tuple of value as float and unit as String
        """
        return self.readPackage()
    
    """ Read twice, there might be an old value in the buffer, so discard the first one.
          return tuple of value as float and unit as String
        """
    def getLastValue(self):
        self.getValue()
        return self.getValue()
    
    # Original methods, might be protected


    def readPackage(self):
        "Read next package and process it"

        if not self.isConnected():
            return NA,"Error not connected"
        
        
        LAENGE=11
        j=0
        a=None
        # outer loop, try to read 3 times, then give up
        while j<3:
            i=0
            buffer = bytearray()
            # inner loop, the multimeter sends 8 byte packages, so read until we have a full line, then process it
            while i<300:
                b=self.dev.read(8,30)
                l=b[0]&0x07
                #buffer.extend(b[1:l+1])
                for j in range(1,l+1):
                    buffer.append(b[j]&0x7F)
                #print(f"i={i}, l={l} b={b} buffer={buffer} len={len(buffer)}")
                if buffer.endswith(b'\r\n'):
                    #print("Ende erkannt")
                    break
                i+=1

            if len(buffer)==2*LAENGE:
                #print(buffer.decode('ascii'))
                a=buffer[0:LAENGE-2]
                b=buffer[LAENGE:2*LAENGE-2]
                if a==b:
                    #print("OK") 
                    break
                else:
                    print("Fehler, unterschiedliche Werte empfangen")
            else:
                print("Fehler, ungültige Länge empfangen")
            j+=1

        # check if we have a valid line           
        if a is None:
            return NA,"Error nothing received"    
        
        # split line
        bereich = a[0] & 0x7
        wert = a[1:5].decode('ascii')
        schalter = a[5] & 0xf
        info = a[6] & 0xf
        kopplung = a[8] & 0xf
        #print(f"bereich={bereich} wert={wert} schalter={schalter} info={info} kopplung={kopplung}")

        # extract unit
        unit = self.utEinheit[schalter];


        # Numerischen Wert zur entsprechenden Einheit
        value = float(wert)*self.utFaktor[bereich][schalter]
        # Vorzeichen aus info herausfummeln
        if info&4:
                value = -value;
        # Kopplung mit an die Einheit anhängen
        if info&1:
                value = NA;
        if kopplung&4:
                unit = [ unit, " (AC)" ];
        if kopplung&8:
                unit = [ unit, " (DC)" ];
        #print(f"Wert={value} {unit}")
        return value,unit


