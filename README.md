# Octave Skript zum Umgang mit E-Technik Laborgeräten und zur Schaltungsauslegung

Ich verwende Octave sehr intensiv. Für Labor Automation ist Octave zwar nicht die erste Wahl, aber ich muss meist erfasste Daten auswerten, und das wiederum ist genau die Stärke von Octave.

Da ich fast nur Octave und fast nie - außer an der Hochschule in den PC Pools - Matlab verwende werden die meisten Skripte nur in Octave lauffähig sein, aber die notwendigen Anpassugnen dürften nicht so gravierend sein. 

## Octave Vorbereitungen

In Octave sollte der Pfad so erweitert werden, dass das Skripte Verzeichnis aufgenommen wird, z.B.

    addpath( [ myhome "/Elektro/Programme/OctaveLab/Skripte" ] );

Dann wird für alle Geräte die instrument-control Package benötigt. Falls sie nicht installiert ist, mit 

    pkg -forge install instrument-control

installieren. Doku unter https://octave.sourceforge.io/instrument-control/index.html

## Verzeichnisse

- Beispiele - Kleine Beispiele zur Verwendung der Klassen und Funktionen aus dem Skripte Ordner
- Experimente - Mein Experimente, häufig zu Prokollen der einzelnen Geräte
- Skripte - Hier liegen Klassen (meist eine Klasse je Gerät) und allerlei nützliche Funktionen.
- Tests - Test Skripte die ich während der Entwicklung genutzt habe.

## Unterstützte Geräte

Ich habe einige Geärte privat, andere stehen in den von mir genutzten Laboren der Hochschule Ansbach.

- BK Precision BK8500 - Elektronische Last
- ELV FZ 7001 - Frequenzzähler
- Fluke 8088 A - Tischmultimeter
- Joy-It JDS 6600 - Signal Generator
- Joy-It RD 6006 - Netzgerät (Kompatibel zu Riden RD6006)
- Korad KA 3005 P - Netzgerät, auch für RND 320-KA3005P
- Metrex M-4650CR - Multimeter (Voltcraft, schon ziemlich alt)
- Peaktech 1265 - Speicher Oszilloskop
- Stamos L-LS-60 - Elektronische Last
- UT 803 - Tischmultimeter


## Hilfsfunktionen
- serialPortReadLine - Ersatz für die readline Funktion aus dem instrument-control Paket wenn serialport verwendet wird.
- srl_getl - Alte Implementierung für serial, ich habe noch nicht alle Klassen von serial auf serialport umgestellt.
