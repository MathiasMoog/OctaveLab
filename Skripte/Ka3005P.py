"""Class for serial / usb communication with the Korad KA3005P Power Supply
   Use also for RND 320-KA3005P
   
   Based on Korad Documentation "KA Series Communication Protocol.pdf"

   Install the pyserial dependency with ``pip install pyserial``.

   Implemented:
    - set and get voltage and current
    - switch on and off
  
   Missing:
    - Everything else

   Copyright, 2021, Mathias Moog, Hochschule Ansbach, Deutschland, CC-BY-NC-SA
"""

from __future__ import annotations

import time
from collections.abc import Iterable

import serial


class Ka3005P:
    """Control output voltage/current and read measurements from a KA3005P."""

    def __init__(self, debug_level: int = 3) -> None:
        self.serial_port: serial.Serial | None = None
        self.debug_level = debug_level

    def connect(self, com: str) -> None:
        """Open the power supply's 9600 baud serial connection."""
        if self.serial_port is not None and self.serial_port.is_open:
            raise RuntimeError("The power supply is already connected")
        self._debug(2, "Ka3005P, connect with port %s\n", com)
        self.serial_port = serial.Serial(port=com, baudrate=9600, timeout=.1)

    def disconnect(self) -> None:
        """Close the serial connection, if one is open."""
        if self.serial_port is not None:
            self.serial_port.close()
            self.serial_port = None

    def get_version(self) -> str:
        """Return the device identification string."""
        port = self._require_connection()
        port.write(b"*IDN?")
        return port.read(255).decode("ascii").strip()

    def get_status(self) -> int:
        """Return the status byte and print its documented status bits."""
        port = self._require_connection()
        port.write(b"STATUS?")
        response = port.read(1)
        if len(response) != 1:
            raise TimeoutError("No status byte received from the power supply")

        status = response[0]
        self._debug(2, "Status\n")
        for bit, text in (
            (0, "ch1 0=cc, 1=cv"),
            (4, "beep"),
            (5, "lock"),
            (6, "output"),
        ):
            self._debug(2, "  %s - %d\n", text, (status >> bit) & 1)
        return status

    def get_current(self) -> float:
        """Return measured output current in amperes."""
        return self._query_float(b"IOUT1?")

    def get_voltage(self) -> float:
        """Return measured output voltage in volts."""
        return self._query_float(b"VOUT1?")

    def set_current(self, current: float) -> None:
        """Set the maximum output current in amperes."""
        self._write_setting(f"ISET1:{current:.3f}")

    def set_voltage(self, voltage: float) -> None:
        """Set output voltage in volts."""
        self._write_setting(f"VSET1:{voltage:.2f}")

    def set_on_off(self, output: bool | int) -> None:
        """Enable or disable the output."""
        if output not in (0, 1, False, True):
            raise ValueError("output must be 0/False (off) or 1/True (on)")
        self._write_setting(f"OUT{int(output)}")

    def voltage_sweep(
        self, voltages: Iterable[float], delay: float
    ) -> tuple[list[float], list[float]]:
        """Set each voltage in turn and return measured voltages and currents."""
        measured_voltages: list[float] = []
        measured_currents: list[float] = []
        for voltage in voltages:
            self.set_voltage(voltage)
            time.sleep(delay)
            measured_voltages.append(self.get_voltage())
            measured_currents.append(self.get_current())
            time.sleep(0.01)
        return measured_voltages, measured_currents

    def current_sweep(
        self, currents: Iterable[float], delay: float
    ) -> tuple[list[float], list[float]]:
        """Set each current limit and return measured voltages and currents."""
        measured_voltages: list[float] = []
        measured_currents: list[float] = []
        for current in currents:
            self.set_current(current)
            time.sleep(delay)
            measured_voltages.append(self.get_voltage())
            measured_currents.append(self.get_current())
            time.sleep(0.01)
        return measured_voltages, measured_currents

    def _query_float(self, command: bytes) -> float:
        port = self._require_connection()
        port.write(command)
        response = port.read(16).decode("ascii").strip()
        return float(response)

    def _write_setting(self, command: str) -> None:
        port = self._require_connection()
        port.write(command.encode("ascii"))
        port.read(16)

    def _require_connection(self) -> serial.Serial:
        if self.serial_port is None or not self.serial_port.is_open:
            raise RuntimeError("The power supply is not connected")
        return self.serial_port

    def _debug(self, level: int, message: str, *args: object) -> None:
        if level <= self.debug_level:
            print(message % args, end="")

    def __enter__(self) -> Ka3005P:
        return self

    def __exit__(self, *_: object) -> None:
        self.disconnect()
