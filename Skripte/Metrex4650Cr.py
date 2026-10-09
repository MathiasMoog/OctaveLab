"""Serial communication with the Voltcraft/Metrex 4650CR multimeter.

Install the serial dependency with ``pip install pyserial``. The meter uses
1200 baud, 7 data bits, no parity, and 2 stop bits.
"""

from __future__ import annotations

import math

import serial


class Metrex4650Cr:
    """Acquire and decode measurements from a Metrex 4650CR multimeter."""

    def __init__(self, debug_level: int = 3) -> None:
        self.serial_port: serial.Serial | None = None
        self.debug_level = debug_level

    def connect(self, com: str) -> None:
        """Open the serial port and discard any startup data from the meter."""
        self._debug(2, "Metrex4650Cr, connect with port %s\n", com)
        self.serial_port = serial.Serial(
            port=com,
            baudrate=1200,
            timeout=1,
            bytesize=serial.SEVENBITS,
            stopbits=serial.STOPBITS_TWO,
            parity=serial.PARITY_NONE,
        )
        self.serial_port.dtr = True
        self.serial_port.rts = False
        self.serial_port.read_until(b"\r")

    def disconnect(self) -> None:
        """Close the serial connection, if one is open."""
        if self.serial_port is not None:
            self.serial_port.close()
            self.serial_port = None

    def acquire_value(self) -> tuple[float, str]:
        """Request one measurement (normal mode) and return its value and unit."""
        port = self._require_connection()
        port.timeout = 1
        port.reset_input_buffer()
        port.write(b"D")
        port.flush()
        return self.get_value()

    def get_value(self) -> tuple[float, str]:
        """Read and decode the next measurement line (also for COMM mode)."""
        port = self._require_connection()
        port.timeout = 2.5
        return self.parse_line(self._read_line(port))

    def get_last_value(self) -> tuple[float, str]:
        """Drain queued COMM-mode measurements and decode the most recent."""
        port = self._require_connection()
        port.timeout = 2.5
        last_line = ""
        while True:
            line = self._read_line(port)
            if not line:
                break
            last_line = line
            port.timeout = 0.1
            self._debug(3, "l=%s\n", line)
        return self.parse_line(last_line)

    def parse_line(self, line: str) -> tuple[float, str]:
        """Decode one meter line into a scaled numeric value and unit."""
        self._debug(3, "parse_line(%s)\n", line)
        if not line:
            self._debug(0, "Error: Nothing to parse, line is empty\n")
            return math.nan, "No Data"
        if len(line) < 10:
            self._debug(
                0,
                "Error: Expect 10 chars, but got only %d (%s)\n",
                len(line),
                line,
            )
            return math.nan, f"Invalid Data: {line}"

        mode = line[0:2]
        value_text = line[3:9]
        unit = line[9:]
        factors = {
            "p": 1e-12,
            "n": 1e-9,
            "u": 1e-6,
            "m": 1e-3,
            "k": 1e3,
            "M": 1e6,
        }
        factor = factors.get(unit[0], 1.0)
        if unit[0] in factors:
            unit = unit[1:]

        try:
            value = float(value_text) * factor
        except ValueError:
            value = math.nan

        if mode[0] != " ":
            unit = f"{unit} ({mode})"
        return value, unit

    def _read_line(self, port: serial.Serial) -> str:
        """Read a CR-terminated ASCII line, excluding its terminator."""
        data = port.read_until(b"\r")
        print("Read until:", data.decode("ascii"))
        if not data.endswith(b"\r"):
            return ""
        data = data[:-1]
        print("Read line:", data.decode("ascii"))
        return data.decode("ascii")

    def _require_connection(self) -> serial.Serial:
        if self.serial_port is None or not self.serial_port.is_open:
            raise RuntimeError("The multimeter is not connected")
        return self.serial_port

    def _debug(self, level: int, message: str, *args: object) -> None:
        if level <= self.debug_level:
            print(message % args, end="")

    def __enter__(self) -> Metrex4650Cr:
        return self

    def __exit__(self, *_: object) -> None:
        self.disconnect()
