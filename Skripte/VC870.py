""" Class for usb communication with the VC870 Multimeter
  
    Based on the VC870 documentation.
    The VC 870 must be set in communication mode with a long press on REL/PC.

    The optical USB adapter creates a HID interface with vendor_id = 6790, product_id 57352, manufacturer WCH.CN, product USB to Serial.

    The communication chip is an HOITEK HE2325U
   
    Windows - hidapi 0.15.0

     See https://pypi.org/project/hidapi/, https://github.com/libusb/hidapi

     https://github.com/libusb/hidapi/releases

    Herunterladen und im Python verzeichnis ablegen: C:/Users/mathias.moog/AppData/Local/Programs/Python/Python313


    pip install hidapi
  
    Unter Windows steht nur das hid Interface zur Verfügung, nicht hidraw.

   
    Implementation details:
   
    Auszug aus https://sigrok.org/wiki/Voltcraft_VC-870
    Siehe Elekto/Laborgeraete/VoltcraftVC870
    SigrokVoltcraft_VC-870.pdf und 124603-in-01-en-Interfaceprotokoll_VC_870_DMM.pdf
   
    Byte(s) 	Name 	Description
    0 	Function code 	Bytes 0 and 1 determine the measurement mode.
    1 	Function select code 	Bytes 0 and 1 determine the measurement mode.
    2 	Range
    3-7 	5 main display digits
    8-12 	5 auxiliary display digits
    13 	?
    14 	?
    15 	Status 	bit 2 vorzeichen
    16 	Option 1
    17 	Option 2
    18 	Option 3
    19 	Option 4
    20 	Dual display
    21 	Line feed 	Always 10 / 0x0a.
    22 	Carriage return 	Always 13 / 0x0d.
   
    Measurement modes:
    Function code 	Function select code 	Measurement mode
    0x30 	0x30 	DCV
    0x30 	0x31 	ACV
    0x31 	0x30 	DCmV
    0x31 	0x31 	Temperature (Celsius and Fahrenheit)
    0x32 	0x30 	Resistance
    0x32 	0x31 	Continuity
    0x33 	0x30 	Capacitance
    0x34 	0x30 	Diode
    0x35 	0x30 	Frequency
    0x35 	0x31 	Loop current, (4-20mA)%
    0x36 	0x30 	DCuA
    0x36 	0x31 	ACuA
    0x37 	0x30 	DCmA
    0x37 	0x31 	ACmA
    0x38 	0x30 	DCA
    0x38 	0x31 	ACA
    0x39 	0x30 	Active/real power + apparent power
    0x39 	0x31 	Power factor + frequency
    0x39 	0x32 	Voltage effective value + current effective value
  
    My first implementation was in Java, later I switched ot Octave and now to Python.
  
    Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
"""

from __future__ import annotations

import math

# Import the correct hid package
import sys
if sys.platform.startswith('linux'):
    import hidraw as hid
else:
    # Windows, install hidapi, but import hid!
    import hid



class VC870:
    """Read and decode measurements sent by a VC870 over a USB connection as HID device."""

    FUNCTION_CODES = (
        "00", "01", "10", "11", "20", "21", "30", "40", "50", "51",
        "60", "61", "70", "71", "80", "81", "90", "91", "92",
    )
    UNITS = (
        "V", "V", "V", "°C", "Ω", "Ω", "F", "V", "Hz", "%",
        "A", "A", "A", "A", "A", "A", "W", "W", "V",
    )
    FACTORS = (
        (1e-4, 1e-3, 1e-2, 1e-1, -1, -1, -1, -1),
        (1e-4, 1e-3, 1e-2, 1e-1, -1, -1, -1, -1),
        (1e-5, -1, -1, -1, -1, -1, -1, -1),
        (1e-2, -1, -1, -1, -1, -1, -1, -1),
        (1e-2, 1e-1, 1, 1e1, 1e2, 1e3, -1, -1),
        (1e-2, 1e-1, 1, 1e1, 1e2, 1e3, -1, -1),
        (1e-12, 1e-11, 1e-10, 1e-9, 1e-8, 1e-7, 1e-6, -1),
        (1e-4, -1, -1, -1, -1, -1, -1, -1),
        (1e-4, -1, -1, -1, -1, -1, -1, -1),
        (1e-5, -1, -1, -1, -1, -1, -1, -1),
        (1e-8, 1e-7, -1, -1, -1, -1, -1, -1),
        (1e-8, 1e-7, -1, -1, -1, -1, -1, -1),
        (1e-6, 1e-5, -1, -1, -1, -1, -1, -1),
        (1e-6, 1e-5, -1, -1, -1, -1, -1, -1),
        (1e-3, -1, -1, -1, -1, -1, -1, -1),
        (1e-3, -1, -1, -1, -1, -1, -1, -1),
        (1e-1, -1, -1, -1, -1, -1, -1, -1),
        (1e-1, -1, -1, -1, -1, -1, -1, -1),
        (1e-1, -1, -1, -1, -1, -1, -1, -1),
    )

    def __init__(self, debug_level: int = 3) -> None:
        self.dev: hid.device = hid.device()
        self.debug_level = debug_level

    def connect(self, path: str | None = None, vendor_id: int = 6790, product_id: int = 57352) -> None:
        """Open a device by HID path or by vendor/product ID."""
        if path:
            try:
                self.dev.open_path(path)
            except (AttributeError, TypeError, OSError):
                try:
                    self.dev.open_path(path.encode("utf-8"))
                except Exception as exc:
                    raise OSError(f"Could not open HID device at {path!r}") from exc
        else:
            self.dev.open(vendor_id, product_id)
        # ToDo, catch the IOError and handle it
        # Set communication properties
        fr = bytes.fromhex('00 80 25 00 00 03')
        #print(fr)
        self.dev.send_feature_report(fr)
        if self.debug_level>2:
            # Print some information about the device
            print("Manufacturer: %s" % self.dev.get_manufacturer_string())
            print("Product: %s" % self.dev.get_product_string())
            print("Serial No: %s" % self.dev.get_serial_number_string())
            print("Report descriptor: %s" % self.dev.get_report_descriptor())

    def disconnect(self) -> None:
        """Close the serial port if it is open."""
        self.dev.close()

    def get_value(self) -> tuple[float, str]:
        """Read and parse the next LF-terminated measurement frame."""
        line = self._read_line()
        if len(line) < 22:
            line = self._read_line()
        return self._parse_line(line)

    def _read_line(self) -> str:
        i=0
        buffer = bytearray()
        while i<300:
            b=self.dev.read(8)
            l=b[0]&0x07
            #buffer.extend(b[1:l+1])
            for j in range(1,l+1):
                buffer.append(b[j]&0x7F)
            #print(f"i={i}, l={l} b={b} buffer={buffer} len={len(buffer)}")
            if buffer.endswith(b'\r\n'):
                if self.debug_level>2:
                    print("Ende erkannt")
                break
            i+=1
        print("Line:",buffer.decode('ascii'))
        return buffer.decode('ascii')

    def _parse_line(self, line: str) -> tuple[float, str]:
        """Decode a VC870 frame into its scaled value and unit."""

        if len(line) < 22:
            return math.nan, f"Invalid Data length: {line}"

        function_code = line[0:2]
        try:
            function_index = self.FUNCTION_CODES.index(function_code)
        except ValueError:
            return math.nan, f"Invalid function code: {function_code}"

        range_index = ord(line[2]) & 0x07
        factor = self.FACTORS[function_index][range_index]
        if factor < 0:
            return math.nan, f"Invalid factor : {factor:g}"

        try:
            display_value = float(line[3:8])
        except ValueError:
            return math.nan, f"Invalid display value: {line[3:8]}"

        sign = -1 if ord(line[15]) & 0x02 else 1
        return sign * display_value * factor, self.UNITS[function_index]

    def _debug(self, level: int, message: str, *args: object) -> None:
        if level <= self.debug_level:
            print(message % args, end="")

    def __exit__(self, *_: object) -> None:
        self.disconnect()
