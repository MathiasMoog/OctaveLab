"""Request measurements from a Metrex 4650CR in normal (non-COMM) mode.

Connect the meter to the computer, update ``COM_PORT`` if needed, and run
from the OctaveLab repository root with:

    python -m Beispiele.Metrex4650CrAquireValueExample

Press E to stop. Install pyserial with ``pip install pyserial`` if necessary.
"""

import msvcrt
import time

from Skripte.Metrex4650Cr import Metrex4650Cr


COM_PORT = "COM31"


def main() -> None:
    meter = Metrex4650Cr()
    try:
        meter.connect(COM_PORT)
        print("Press E to stop.")
        while True:
            value, unit = meter.acquire_value()
            print(f"{value:g} {unit}")

            deadline = time.monotonic() + 1
            while time.monotonic() < deadline:
                if msvcrt.kbhit() and msvcrt.getwch().upper() == "E":
                    print("Stopping.")
                    return
                time.sleep(0.05)
    finally:
        meter.disconnect()


if __name__ == "__main__":
    main()
