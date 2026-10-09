#! /bin/env python3
"""
Talk to a UNI-T UT8803E bench multimeter
Original Code from https://github.com/philpagel/ut8803e

Ubuntu Noble Numbat:

- Installiere
sudo apt install python3-hidapi python3-construct
-> Angepasste cp2110.py hier im Verzeichnis
  In python3-hid ist hidapi enthalten.


- Zugriffsrechte auf CP2110 für normale Nutzer
sudo nano  /etc/udev/rules.d/50-usb-serial.rules
SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea80", MODE="0666"

- Octve Integration mit Pythonic 
  Wrapper Klasse Ut8803e.m und Ut8803eTest

Windows:

- pip install hidapi construct
- Octave Integration zur Zeit (2024, Octave 8.4) nicht möglich, da Pythonic nicht compiliert



Adopted by Mathias Moog for OctaveLab
"""

from collections import OrderedDict
import construct as C

# Verwende die lokale cp2110.py Datei, die auf hidapi angepasst wurde.
import Skripte.cp2110 as cp2110


class ut8000:
    "Device class for uni-t ut8xxx bench multimeters"

    cmd_bytes = {
            "get_ID"        : b"\x58\x00",
            "hold"          : b"\x46\x00",
            "brightness"    : b"\x47\x00",
            "select"        : b"\x48\x00",
            "range_manual"  : b"\x49\x00",
            "range_auto"    : b"\x4a\x00",
            "minmax"        : b"\x4b\x00",
            "exitminmax"    : b"\x4c\x00",
            "rel"           : b"\x4d\x00",
            "d_val"         : b"\x4e\x00",
            "q_val"         : b"\x4f\x00",
            "r_val"         : b"\x51\x00",
            "exit_dqr"      : b"\x50\x00",
            "confirm"       : b"\x5a\x00",
            }

    """modes
      name - Human readable name, not used in interface
      unit - Name of the Unit without prefix
      mult - Power of 10 for multipliers (instead of named prefixes)
      range - measurement range, not used in interface
    """ 
    mode = [{
                "name" : "AC Voltage",     
                "unit" : "V",
                "mult" : [-3,0,0,0,0],
                "range" : ["600mV", "6V", "60V", "600V", "750V"],
             },
            {
                "name" : "DC Voltage",	    
                "unit" : "V",
                "mult" : [-3,0,0,0,0],
                "range" : ["600mV", "6V", "60V", "600V", "1000V"],
            },
            {
                "name" : "AC Current µA",  
                "unit" : "A", 
                "mult" : [-6,-3],
                "range" : ["600µA", "6mA"],
            },
            {
                "name" : "AC Current mA",  
                "unit" : "A", 
                "mult" : [-3,-3], 
                "range" : ["60mA", "600mA"],
            },
            {
                "name" : "AC Current A",   
                "unit" : "A",
                "mult" : [0], 
                "range" : ["10A"],
            },
            {
                "name" : "DC Current µA",  
                "unit" : "A", 
                "mult" : [-6,-3],
                "range" : ["600µA", "6mA"],
            },
            {
                "name" : "DC Current mA",
                "unit" : "A", 
                "mult" : [-3,-3],  
                "range" : ["60mA", "600mA"],
            },
            {
                "name" : "DC Current A",   
                "unit" : "A",
                "mult" : [0], 
                "range" : ["10A"],
            },
            {
                "name" : "Resistance",	    
                "unit" : "Ω", 
                "mult" : [0,3,3,3,6,6],
                "range" : ["600Ω", "6kΩ", "60kΩ", "600kΩ", "6MΩ", "60MΩ"],
            },
            {
                "name" : "Continuity",	    
                "unit" : "", 
                "mult" : [0],
                "range" : ["NA"] 
            },
            {
                "name" : "Diode",	        
                "unit" : "V", 
                "mult" : [0],
                "range" : ["NA"] 
            },
            {
                "name" : "Inductance L",   
                "unit" : "H", 
                "mult" : [-6,-3,-3,-3,0,0,0],
                "range" : ["600µH", "6mH", "60mH", "600mH", "6H", "60H", "100H"] 
            },
            {
                "name" : "Inductance Q",   
                "unit" : "", 
                "mult" : [0],
                "range" : ["NA"] 
            },
            {
                "name" : "Inductance R",   
                "unit" : "Ω", 
                "mult" : [0,0,3,3,3,6],
                "range" : ["60Ω", "600Ω", "6kΩ", "60kΩ", "600kΩ", "2MΩ"], 
            },
            {
                "name" : "Capacitance C",  
                "unit" : "F", 
                "mult" : [-9,-9,-9,-6,-6,-6,-3],
                "range" : ["6nF", "60nF", "600nF", "6µF", "60µF", "600µF", "6mF"],
            },
            {
                "name" : "Capacitance D",  
                "unit" : "", 
                "mult" : [0] * 5, 
                "range" : ["NA0", "NA1", "NA2", "NA3","NA4"] 
            }, # XXX FIXME: what do the ranges mean?
            {
                "name" : "Capacitance R",  
                "unit" : "Ω", 
                "mult" : [0,0,3,3,3,6],
                "range" : ["60Ω", "600Ω", "6kΩ", "60kΩ", "600kΩ", "2MΩ"],
            },
            {
                "name" : "Triode hFE",
                "unit" : "", 
                "mult" : [0] * 5, 
                "range" : ["NA0", "NA1", "NA2", "NA3","NA4"],
            }, # XXX FIXME meaning of ranges?
            {
                "name" : "Thyrisor SCR",  
                "unit" : "", 
                "mult" : [0] * 5, 
                "range" : ["NA0", "NA1", "NA2", "NA3","NA4"],
            }, # XXX FIXME
            {
                "name" : "Temp °C",	    
                "unit" : "°C", 
                "mult" : [0] * 3, 
                "range" : ["-40 - 0°C", "0 - 400°C", "400 - 1000°C"],
            },
            {
                "name" : "Temp F",	        
                "unit" : "°F",
                "mult" : [0] * 3, 
                "range" : ["-40 - 32°F", "32 - 752°F", "752 - 1832°F"] 
            },
            {
                "name" : "Freq",	        
                "unit" : "Hz", 
                "mult" : [0,3,3,3,6,6],
                "range" : ["600Hz", "6kHz", "60kHz", "600kHz", "6MHz", "20MHz"], 
            },
            {
                "name" : "Duty cycle",	    
                "unit" : "%", 
                "mult" : [0] * 6, 
                "range" : ["600Hz", "6kHz", "60kHz", "600kHz", "6MHz", "20MHz"] 
            },
            ]

    prefix = ["n", 'µ', 'm', '', 'k', 'M', 'G']
    prefix = ["M", "", '', '', '', '', '', 'k']

    # data package
    package = C.Struct(
            "signature" / C.Const(b"\xab\xcd"),
            "length"    / C.Rebuild(C.Int8ub, C.len_(C.this.payload)+2),
            "payload"   / C.Bytes(C.this.length-2),
            "checksum"  / C.Int16ub,
            )

    # measurement data payload
    mdata = C.Struct(
            "rectype"   / C.Bytes(1),
            "mode"      / C.Int8ub,
            "range"     / C.PaddedString(1, "ascii"),
            "value"     / C.PaddedString(6, "ascii"),
            "stat"      / C.Bytes(7),
            )

    # measurement flags
    stat = C.BitStruct(
            "unk00"         / C.Flag, 
            "unk01"         / C.Flag,
            "unk02"         / C.Flag,
            "unk03"         / C.Flag,
            "unk04"         / C.Flag, # XXX bargraph length?
            "unk05"         / C.Flag,
            "unk06"         / C.Flag,
            "unk07"         / C.Flag,

            "unk10"         / C.Flag,
            "unk11"         / C.Flag,
            "unk12"         / C.Flag,
            "unk13"         / C.Flag,
            "unk14"         / C.Flag,
            "unk15"         / C.Flag,
            "unk16"         / C.Flag,
            "unk17"         / C.Flag, # XXX: serial/parallel?

            "unk20"         / C.Flag,
            "unk21"         / C.Flag,
            "unk22"         / C.Flag,
            "unk23"         / C.Flag,
            "unk24"         / C.Flag,
            "OL"            / C.Flag,
            "unk26"         / C.Flag,
            "Hold"          / C.Flag,
                            
            "unk31"         / C.Flag,
            "unk32"         / C.Flag,
            "unk33"         / C.Flag,
            "unk34"         / C.Flag,
            "unk35"         / C.Flag,
            "err"           / C.Flag,
            "manrange"      / C.Flag,
            "rel"           / C.Flag,
                            
            "unk41"         / C.Flag,
            "unk42"         / C.Flag,
            "unk43"         / C.Flag,
            "unk44"         / C.Flag,
            "unk45"         / C.Flag,
            "unk46"         / C.Flag,
            "max"           / C.Flag,
            "min"           / C.Flag,

            "unk51"         / C.Flag,
            "unk52"         / C.Flag,
            "unk53"         / C.Flag,
            "unk54"         / C.Flag,
            "unk55"         / C.Flag,
            "unk56"         / C.Flag,
            "unk57"         / C.Flag,
            "unk58"         / C.Flag,

            "unk61"         / C.Flag,
            "unk62"         / C.Flag,
            "unk63"         / C.Flag,
            "unk64"         / C.Flag,
            "unk65"         / C.Flag,
            "unk66"         / C.Flag,
            "forward"       / C.Flag, # diode polarity: <-
            "reverse"       / C.Flag, # diode polarity: ->
            )


    def __init__(self):
        self.iface = None
        self.buf = bytearray()

    def __del__(self):
        self.disconnect()

    # OctaveLab Like Interface

    def isConnected(self):
        """Check if connected to multimeter"""
        if self.iface:
          return True
        return False
        
    def connect(self):
        """ Try to connect to multimeter.
          Read ID after connection
        """
        if self.isConnected():
            print("Allready connectd")
            return
        self.iface = cp2110.CP2110Device()
        self.ID = None  # instrument ID, not jet set

        # setup interface
        self.iface.set_uart_config(cp2110.UARTConfig(
                            baud=9600,
                            parity=cp2110.PARITY.NONE,
                            flow_control=cp2110.FLOW_CONTROL.DISABLED,
                            data_bits=cp2110.DATA_BITS.EIGHT,
                            stop_bits=cp2110.STOP_BITS.SHORT)
                          )
        self.iface.enable_uart()
        print('UT800x device connected')

        # try to get ID
        self.iface.purge_fifos()
        self.send_request("get_ID")
        self.send_request("confirm")
        i=0
        while not self.ID and i<10:
            self.readPackage()
            i=i+1
        print(f'ID {self.ID}')


    def disconnect(self):
        """ Disconnect from multimeter."""
        if (self.isConnected()):
            try:
                self.iface.purge_fifos()
                self.iface.close()
            except:
                pass 
            self.iface = None
            self.buf.clear()

    def getValue(self):
        """ Get the first value / unit pair from serial buffer.
          return tuple of value as float and unit as String
        """
        dat = self.readPackage()
        #print(dat)
        return float(dat["value"])*(10.0**dat["mult"]), dat["unit"]
    
    """ Empty Buffer, wait for next measurement.
          return tuple of value as float and unit as String
        """
    def getLastValue(self):
        self.iface.purge_fifos()
        self.buf.clear()
        return self.getValue()
    
    # Original methods, might be protected

    def send_request(self, cmd):
        "send cmd request to the instrument"

        payload = self.cmd_bytes[cmd]
        length = len(payload) + 2
        package = self.package.build(
                dict(
                    length = length,
                    payload=payload,
                    checksum=sum(b"\xab\xcd" + length.to_bytes(1, "big") + payload),
                    ),
                )
        self.iface.write(package)
        


    def readPackage(self):
        "Read next packed process it"
        
        
        while True:
            #self.buf.extend(self.iface.read(63)) # Original, maximale länge
            self.buf.extend(self.iface.read(2)) # Windows, ein byte gültig, danach nur 0en
            #print(f'read {len(self.buf)} bytes', file=sys.stderr)

            if len(self.buf) >= 26:
                # seek package signature
                while not self.buf.startswith(b"\xab\xcd"):
                    if len(self.buf)==0:
                        print("No starting code found, read next bytes")
                        break
                    print(f'shift {self.buf[0]:02x}')
                    del(self.buf[0])
                else:
                    dat = self.parsepackages()
                    if (dat):
                        return dat


    def parsepackages(self):
        "parse stream buffer and return data as a dict"

        while len(self.buf) >= 26:
            package = self.package.parse(self.buf)
            rawpackage = self.package.build(package)
            checksum = sum(rawpackage[:-2])
            del(self.buf[:len(rawpackage)])

            if checksum != package["checksum"]:
                print("Warning: Checksum mismatch")

            if package["payload"].startswith(b"\x02"): # data package
                mvals = self.mdata.parse(package["payload"])
                stat = self.stat.parse(mvals["stat"])
                dat = OrderedDict([
                    #("No",          self.package_no),
                    #("timestamp",   datetime.datetime.fromtimestamp(time.time())),
                    ("mode",        self.mode[mvals["mode"]]["name"]),
                    ("range",       self.mode[mvals["mode"]]["range"][int(mvals["range"])]),
                    ("value",       mvals["value"]),
                    ("mult",        self.mode[mvals["mode"]]["mult"][int(mvals["range"])]),
                    ("unit",        self.mode[mvals["mode"]]["unit"]),
                    ("OL",          "OL" if stat["OL"] else ""),
                    ("hold",        "hold" if stat["Hold"] else ""),
                    ("rel",         "rel" if stat["rel"] else ""),
                    ("polarity",    "forward" if stat["forward"] else "reverse" if stat["reverse"] else ""),
                    ("manrange",    "manual" if stat["manrange"] else "auto"),
                    ("minmax",      "min" if stat["min"] else "max" if stat["max"] else ""),
                    ("err",         "Err" if stat["err"] else ""),
                    ("stat",        mvals["stat"]),
                ])
                if dat["err"] == "Err" or dat["OL"] == "OL":
                        dat["value"] = ""
                        dat["unit"] = "Err"
                return dat
            elif package["payload"].startswith(b"\x00"): # device ID package
                self.ID = package["payload"][1:].decode("utf8")
                dat = OrderedDict([("ID", self.ID)])
                return dat
            else:
                print(f"Warning: Unknown package type {hex(package['payload'][0])}. Skipping")



