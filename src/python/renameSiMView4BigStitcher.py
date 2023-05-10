#! python3

import argparse
import os
import re
import threading
from pathlib import Path, PurePath
from sys import exit
from time import sleep

"""
Parser for command line arguments
"""
def parse_args():
    parser = argparse.ArgumentParser(description='Converts a SiMView data directory into a folder of symlinks for BigStitcher dataset definition')
    parser.add_argument('input', type=Path, help='path to image files')
    parser.add_argument('-removeSlices', type=Path, help='number of z-slices to remove. Defaults to zero.', dest='removeSlices', default=0)
    args = parser.parse_args()

    if not args.input.is_dir():
        exit(f'error: \'%s\' is does not exist or is not a folder.' % args.input)

    return args

 

"""
Parser for filenames + metadata
"""
def parse_files(path1,Nremove):

    # First find all the timepoint folders
    tFolders = os.listdir(path1)
    patternT = re.compile('TM(\d{5})')
    tList = []
    for f in tFolders:
        m = patternT.fullmatch(f)
        if m:
            tList.append(m.group(1))
    # print(tList)

    # Use the first timepoint to determine the other information about the experiment
    # ASSUMPTION: the experiment doesn't change over time -- could be wrong for more complex SiMView set ups
    tNow = 'TM'+str(tList[0])
    tfNow = path1 / tNow / 'ANG000'
    files = os.listdir(tfNow) # ASSUMPTION: one angle experiment set up
    patternF = re.compile('SPC00_TM'+tList[0]+'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{4}).tif')
    chList = []
    camList = []
    zList = []
    for f in files:
        m = patternF.fullmatch(f)
        if m:
            if m.group(1) not in camList:
                camList.append(m.group(1))
            if m.group(2) not in chList:
                chList.append(m.group(2))
            if m.group(3) not in zList:
                zList.append(m.group(3))
    zMax = int(max(zList))
    # print(zMax)

    # rename the image files
    for idx, t in enumerate(tList):
        tNow = 'TM'+str(tList[idx])
        tfNow = path1 / tNow / 'ANG000'
        print(tNow)

        # Rename twice because otherwise you run issue that, e.g., z0300 already exists when you want to rename z0000 --> z0300
        # If the file names aren't the exact number of z-padding, etc., the BigStitcher plugin can't read it
        # So --> rename to a tmp name, then switch back to the same format as before.

        # tmp renaming
        files = os.listdir(tfNow) # ASSUMPTION: one angle experiment set up
        patternF = re.compile('SPC00_TM'+tList[idx]+'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{4}).tif')
        for f in files:
            m = patternF.fullmatch(f)
            if m:
                if m.group(1)=='1': # Only rename files on the second camera
                    newZ = zMax-int(m.group(3))
                    newFile = 'SPC00_'+tNow+'_ANG000_CM'+m.group(1)+'_CHN'+m.group(2)+'_PH0_PLN'+str(newZ).zfill(5)+'.tif'
                    if os.name == 'nt': # windows
                        cmd = 'ren '+ str(tfNow/f) + ' ' + newFile                        
                    else:
                        cmd = 'mv '+ str(tfNow/f) + ' ' + str(tfNow/newFile)
                    threading.Thread(target=os.system,args=(cmd,)).start()
                    # os.system(cmd)
                    # print(cmd)

        # Don't proceed to the next step until these threads finish running
        # This avoids duplicate issues
        Nrunning = threading.active_count()
        # print(Nrunning)
        while Nrunning>1:
            sleep(0.05)
            Nrunning = threading.active_count()
            # print(Nrunning)

        # final renaming
        files = os.listdir(tfNow) # ASSUMPTION: one angle experiment set up
        patternF = re.compile('SPC00_TM'+tList[idx]+'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{5}).tif')
        for f in files:
            m = patternF.fullmatch(f)
            if m:                
                newZ = int(m.group(3))
                newFile = 'SPC00_'+tNow+'_ANG000_CM'+m.group(1)+'_CHN'+m.group(2)+'_PH0_PLN'+str(newZ).zfill(4)+'.tif'
                if os.name == 'nt': # windows
                    cmd = 'ren '+ str(tfNow/f) + ' ' + newFile                        
                else:
                    cmd = 'mv '+ str(tfNow/f) + ' ' + str(tfNow/newFile)
                threading.Thread(target=os.system,args=(cmd,)).start()
                # os.system(cmd)
                # print(cmd)


if __name__ == '__main__':
    # get command line arguments
    args = parse_args()

    # make the symlinks
    data = parse_files(args.input,args.removeSlices)

    # make sure none of the threads are still running before reporting that you are done
    Nrunning = threading.active_count()
    # print(Nrunning)
    while Nrunning>1:
        sleep(0.05)
        Nrunning = threading.active_count()
        # print(Nrunning)

    print('Done')