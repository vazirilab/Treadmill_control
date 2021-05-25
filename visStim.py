#!/usr/bin/env python
# -*- coding: utf-8 -*-

from psychopy import core, visual, event, monitors
import nidaqmx
import sys, logging, datetime

# config params
stim_duration = 2
ori_increment = 45  # degrees
ori_max = 135
phase_increment = 0.01

arg_list = sys.argv[1:]
if len(arg_list) >= 1:
    logfile_fullpath = arg_list[0]
else:
    logfile_fullpath = 'vis_stim_' + datetime.datetime.now().strftime('%Y-%m-%dT%H%M%S') + '.log'

logFormatter = logging.Formatter("%(asctime)s [%(levelname)-5.5s]  %(message)s")
logger = logging.getLogger()
logger.setLevel(logging.INFO)
fileHandler = logging.FileHandler(logfile_fullpath)
fileHandler.setFormatter(logFormatter)
logger.addHandler(fileHandler)
consoleHandler = logging.StreamHandler()
consoleHandler.setFormatter(logFormatter)
logger.addHandler(consoleHandler)

monitor = monitors.Monitor('treadmill_monitor')  # , width=30, distance=40

# create a window to draw in
win = visual.Window([1920, 1080], allowGUI=False, screen=1, monitor=monitor)

# mask="raisedCos", maskParams={'fringeWidth': 0.1}
# mask="gauss", maskParams={'sd': 3}
grating = visual.GratingStim(win, tex="sin", mask="raisedCos", maskParams={'fringeWidth': 0.2}, texRes=256, units='deg', 
    size=[30.0, 30.0], sf=[0.07, 0], ori=0, name='grating1')

trialClock = core.Clock()

try:
    with nidaqmx.Task() as task:
        task.di_channels.add_di_chan("PXI1Slot5/Port0/Line5")
        # repeat drawing for each frame
        while True:
            di_sample = task.read(number_of_samples_per_channel=1)
            
            if di_sample == [True]:
                stim_start = trialClock.getTime()
                logger.info(str(stim_start) + ': ori ' + str(grating.ori))
                while trialClock.getTime() - stim_start <= stim_duration:
                    grating.draw()
                    win.flip()
                    grating.phase += phase_increment
                win.flip()
                if grating.ori >= ori_max:
                    grating.ori = 0
                else:
                    grating.ori += ori_increment
            
            # handle key presses each frame
            key_list = event.getKeys(keyList=['escape', 'q', 'r'])
            if 'q' in key_list or 'escape' in key_list:
                break
            elif 'r' in key_list:
                logger.info(str(trialClock.getTime()) + ': Clock & orientation reset')
                trialClock.reset()
                grating.ori = 0

except Exception as e:
    import traceback
    logger.error(traceback.format_exc())

finally:
    handlers = logger.handlers[:]
    for handler in handlers:
        handler.close()
        logger.removeHandler(handler)
    logging.shutdown()
    win.close()
    core.quit()
