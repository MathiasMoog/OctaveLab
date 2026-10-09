"""Serial and UDP communication with the Stamos S-LS-60 electronic load.

    Based on Stamos Documentation "Communication Commands with Computer V2.10.pdf"
  
    Implemented:
    - Measure voltage, current and power
    - Function (VOLT|CURR|RES|POW|SHORT) access
    - CC Mode (basic functionality)
    - CV,CR,CP Mode (not yet tested)

    Missing:
    - Everything else
  
   Copyright, 2022, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA

    The serial interface uses 115200 baud, 8 data bits, no parity, and 1 stop bit.
    Install pyserial with ``pip install pyserial``.

    The UDP implementation uses the socket package.
"""

from __future__ import annotations

import math
import re
import socket
from typing import TypeAlias

import serial

Connection: TypeAlias = serial.Serial | socket.socket


class Sls60:
    """Read measurements and control operating modes of a Stamos S-LS-60."""

    _NUMBER_PREFIX = re.compile(
        r"^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)"
    )
    _FUNCTIONS = {"VOLT", "CURR", "RES", "POW", "SHORT"}

    def __init__(self, debug_level: int = 1) -> None:
        self.serial_port: Connection | None = None
        self.udp = False
        self.ip: str | None = None
        self.udp_port: int | None = None
        self.debug_level = debug_level

    def connect(self, com: str, udp_port: int = 18190) -> bool:
        """Connect over serial, or UDP when ``com`` is an IPv4 address.

        Returns ``True`` when the load responds to the identification query.
        """
        if self.serial_port is not None:
            raise RuntimeError("The electronic load is already connected")

        if com.startswith("192."):
            connection = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            connection.bind(("", udp_port))
            connection.settimeout(0.1)
            self.serial_port = connection
            self.udp = True
            self.ip = com
            self.udp_port = udp_port
        else:
            self.serial_port = serial.Serial(
                port=com,
                baudrate=115200,
                timeout=0.2,
                bytesize=serial.EIGHTBITS,
                stopbits=serial.STOPBITS_ONE,
                parity=serial.PARITY_NONE,
            )
            self.udp = False
            self.ip = None
            self.udp_port = None

        try:
            self.get_version()
        except TimeoutError:
            self._debug(0, "No identification response from electronic load\n")
            self.disconnect()
            return False
        return True

    def disconnect(self) -> None:
        """Close the active connection."""
        if self.serial_port is not None:
            self.serial_port.close()
            self.serial_port = None
        self.udp = False
        self.ip = None
        self.udp_port = None

    def get_version(self) -> str:
        """Return the device identification response."""
        return self._query("*IDN?")

    def measure_voltage(self) -> float:
        """Return measured voltage in volts."""
        return self._query_number(":MEASure:VOLTage?", "V")

    def measure_current(self) -> float:
        """Return measured current in amperes."""
        return self._query_number(":MEASure:CURRent?", "A")

    def measure_power(self) -> float:
        """Return measured power in watts."""
        return self._query_number(":MEASure:POWer?", "W")

    def set_function(self, function: str) -> None:
        """Select VOLT, CURR, RES, POW, or SHORT operating mode."""
        function = function.upper()
        if function not in self._FUNCTIONS:
            allowed = ", ".join(sorted(self._FUNCTIONS))
            raise ValueError(f"function must be one of: {allowed}")
        self._send(f":FUNCtion {function}")

    def get_function(self) -> str:
        """Return the selected operating mode."""
        return self._query(":FUNCtion?")

    def set_cc_current(self, current: float) -> None:
        """Set constant-current mode current in amperes."""
        self._send(f":CURRent {current:.4f}A")

    def get_cc_current(self) -> float:
        """Return the constant-current setting in amperes."""
        return self._query_number(":CURRent?", "A")

    def set_cv_voltage(self, voltage: float) -> None:
        """Set constant-voltage mode voltage in volts."""
        self._send(f":VOLTage {voltage:.4f}V")

    def get_cv_voltage(self) -> float:
        """Return the constant-voltage setting in volts."""
        return self._query_number(":VOLTage?", "V")

    def set_cr_resistance(self, resistance: float) -> None:
        """Set constant-resistance mode resistance in ohms."""
        self._send(f":RESistance {resistance:.3f}OHM")

    def get_cr_resistance(self) -> float:
        """Return the constant-resistance setting in ohms."""
        return self._query_number(":RESistance?", "OHM")

    def set_cp_power(self, power: float) -> None:
        """Set constant-power mode power in watts."""
        self._send(f":POWer {power:.4f}W")

    def get_cp_power(self) -> float:
        """Return the constant-power setting in watts."""
        return self._query_number(":POWer?", "W")

    def get_input(self) -> bool:
        """Return whether the electronic load input is enabled."""
        state = self._query(":INPut?").upper()
        if state == "ON":
            return True
        if state == "OFF":
            return False
        raise ValueError(f"Unknown electronic load input state: {state!r}")

    def set_input(self, on: bool) -> None:
        """Enable or disable the electronic load input."""
        if not isinstance(on, bool):
            raise TypeError("on must be a bool")
        self._send(f":INPut {'ON' if on else 'OFF'}")

    def _query_number(self, command: str, unit: str) -> float:
        response = self._query(command)
        match = self._NUMBER_PREFIX.match(response)
        if match is None:
            self._debug(0, "Error: No numerical value in answer %s\n", response)
            return math.nan
        remainder = response[match.end() :].strip()
        if not remainder.upper().startswith(unit.upper()):
            self._debug(
                0,
                "Error: Expected unit %s in answer %s\n",
                unit,
                response,
            )
            return math.nan
        return float(match.group(1))

    def _query(self, command: str) -> str:
        self._send(command)
        return self._read_line()

    def _send(self, command: str) -> None:
        connection = self._require_connection()
        payload = (command + "\n").encode("ascii")
        if self.udp:
            if self.ip is None or self.udp_port is None:
                raise RuntimeError("UDP connection is missing its destination")
            connection.sendto(payload, (self.ip, self.udp_port))
        else:
            connection.write(payload)
        self._debug(3, "sls send: %s\n", command)

    def _read_line(self) -> str:
        connection = self._require_connection()
        if not self.udp:
            response = connection.read_until(b"\n")
            if not response.endswith(b"\n"):
                raise TimeoutError("Timed out waiting for electronic load response")
            line = response.decode("ascii").rstrip("\r\n").lstrip()
            if not line:
                raise TimeoutError("Received an empty response from electronic load")
            return line

        if self.ip is None:
            raise RuntimeError("UDP connection is missing its destination")
        assert isinstance(connection, socket.socket)
        for _ in range(30):
            try:
                response, _address = connection.recvfrom(4096)
                line = response.decode("ascii").strip()
                if line:
                    return line
            except TimeoutError:
                continue
        raise TimeoutError("Timed out waiting for electronic load UDP response")

    def _require_connection(self) -> Connection:
        if self.serial_port is None:
            raise RuntimeError("The electronic load is not connected")
        if isinstance(self.serial_port, serial.Serial) and not self.serial_port.is_open:
            raise RuntimeError("The electronic load serial connection is closed")
        return self.serial_port

    def _debug(self, level: int, message: str, *args: object) -> None:
        if level <= self.debug_level:
            print(message % args, end="")

    def __exit__(self, *_: object) -> None:
        self.disconnect()
