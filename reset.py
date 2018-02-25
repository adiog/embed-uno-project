import serial
import sys


conn = serial.Serial(sys.argv[1], 1200)

conn.setRTS(True)
conn.setDTR(False)

conn.close()

