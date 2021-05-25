# -*- coding: utf-8 -*-
import serial
import msvcrt
import time
import datetime
import sys

arg_list = sys.argv[1:]
if len(arg_list) >= 1:
    filename = arg_list[0]
else:
    filename = 'wisim_arduino_' + datetime.datetime.now().strftime('%Y-%m-%dT%H%M%S') + '.log'

try:
	logfile_handle = False
	ser = serial.Serial('COM7', 115200, timeout=0.1)
	ser.write(b'r')  # reset arduino to "waiting for trigger" state
	#filename = input("Enter output file name base: ")
	logfile_handle = open(filename + '.txt', 'w')

	while(True):
		try:
			if msvcrt.kbhit():
				ch = msvcrt.getch()
				print(ch)
				if ch == b'q':
					break
				elif ch == b'r':
					ser.write(b'r')

			if ser.in_waiting == 0:
				time.sleep(0.005)
				continue

			s = ser.readline().decode('ascii').rstrip()  # decode("ascii")
			# values = s.split('\t')
			if s != '':
				print(s)
				logfile_handle.write(s + '\n')
		except Exception as e:
			print(e)		

except Exception as e:
	print(e)

finally:
	if logfile_handle:
		logfile_handle.close()
	ser.close()
