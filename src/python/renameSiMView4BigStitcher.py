#! /misc/local/python-3.8.2/bin/python3

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
    parser = argparse.ArgumentParser(description='Changes file names in a SiMView data directory to accomodate BigStitcher.')
    parser.add_argument('input', type=Path, help='path to image files')
    parser.add_argument('-flipZ', action='store_true', help='flag to change the numerical order of the z-slices on CM1. Defaults to false.', dest='flipZ', default=False)
    parser.add_argument('-flipCamera', action='store_true', help='flag to change the numerical order of the cameras. Defaults to false.', dest='flipCamera', default=False)
    args = parser.parse_args()

    if not args.input.is_dir():
        exit(f'error: \'%s\' is does not exist or is not a folder.' % args.input)

    return args

"""
Use the first timepoint to determine the range of the various file types
"""
def parse_filenames(path1):

    # First find all the timepoint folders
    tFolders = os.listdir(path1)
    patternT = re.compile(r'TM(\d{5})')
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
    patternF = re.compile(r'SPC00_TM'+tList[0]+r'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{4}).tif')
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

    return tList,chList,camList,zList

"""
Reorder the z-slices of CM1 so that 0 is renamed to the maxZ and maxZ is 0.
"""
def run_zFlip(path1):

    tList,chList,camList,zList = parse_filenames(path1)
    zMax = int(max(zList))
    # print(zMax)

    # flip the order of the z-slices
    for idx, t in enumerate(tList):
        tNow = 'TM'+str(tList[idx])
        tfNow = path1 / tNow / 'ANG000'
        print(tNow)

        # Rename twice because otherwise you run issue that, e.g., z0300 already exists when you want to rename z0000 --> z0300
        # If the file names aren't the exact number of z-padding, etc., the BigStitcher plugin can't read it
        # So --> rename to a tmp name, then switch back to the same format as before.

        # tmp renaming
        files = os.listdir(tfNow) # ASSUMPTION: one angle experiment set up
        patternF = re.compile(r'SPC00_TM'+tList[idx]+r'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{4}).tif')
        for f in files:
            m = patternF.fullmatch(f)
            if m:
                if m.group(1)=='1': # Only rename files on the second camera
                    newZ = zMax-int(m.group(3))
                    newFile = 'SPC00_'+tNow+'_ANG000_CM'+m.group(1)+'_CHN'+m.group(2)+'_PH0_PLN'+str(newZ).zfill(5)+'.tif'
                    if os.name == 'nt': # windows
                        cmd = 'ren "'+ str(tfNow/f) + '" "' + newFile + '"'                        
                    else:
                        cmd = 'mv "'+ str(tfNow/f) + '" "' + str(tfNow/newFile) + '"'
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
        patternF = re.compile(r'SPC00_TM'+tList[idx]+r'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{5}).tif')
        for f in files:
            m = patternF.fullmatch(f)
            if m:                
                newZ = int(m.group(3))
                newFile = 'SPC00_'+tNow+'_ANG000_CM'+m.group(1)+'_CHN'+m.group(2)+'_PH0_PLN'+str(newZ).zfill(4)+'.tif'
                if os.name == 'nt': # windows
                    cmd = 'ren "'+ str(tfNow/f) + '" "' + newFile + '"'                       
                else:
                    cmd = 'mv "'+ str(tfNow/f) + '" "' + str(tfNow/newFile) + '"'
                threading.Thread(target=os.system,args=(cmd,)).start()
                # os.system(cmd)
                # print(cmd)



"""
Reorder the cameras such that CM1->CM0 and CM0->CM1.
"""
def run_cameraFlip(path1):

    tList,chList,camList,zList = parse_filenames(path1)
    if len(camList)>2:
        exit(f'ERROR: Expected maximum two cameras.')
    elif len(camList)==2:
        if not((camList[0]=='0') and (camList[1]=='1')):
            exit(f'ERROR: Expected the two cameras to be CM0 and CM1.')
    elif len(camList)==1:
        if not(camList[0]=='0' or camList[0]=='1'):
            exit(f'ERROR: Expected the cameras to be either CM0 or CM1.')
    else:
        exit(f'ERROR: Unexpected camera naming error.')


    # flip the cameras 0-->1, 1-->0
    for idx, t in enumerate(tList):
        tNow = 'TM'+str(tList[idx])
        tfNow = path1 / tNow / 'ANG000'
        print(tNow)

        # Rename twice because otherwise you run issue that, e.g., z0300 already exists when you want to rename z0000 --> z0300
        # If the file names aren't the exact number of zero-padding, etc., the BigStitcher plugin can't read it
        # So --> rename to a tmp name, then switch back to the same format as before.

        # tmp renaming
        files = os.listdir(tfNow) # ASSUMPTION: one angle experiment set up
        patternF = re.compile(r'SPC00_TM'+tList[idx]+r'_ANG000_CM(\d)_CHN(\d{2})_PH0_PLN(\d{4}).tif')
        for f in files:
            m = patternF.fullmatch(f)
            if m:
                newCam = 1-int(m.group(1))
                newFile = 'SPC00_'+tNow+'_ANG000_CM'+str(newCam).zfill(3)+'_CHN'+m.group(2)+'_PH0_PLN'+m.group(3)+'.tif'

                if os.name == 'nt': # windows
                    cmd = 'ren "'+ str(tfNow/f) + '" "' + newFile + '"'                        
                else:
                    cmd = 'mv "'+ str(tfNow/f) + '" "' + str(tfNow/newFile) + '"'
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
        patternF = re.compile(r'SPC00_TM'+tList[idx]+r'_ANG000_CM(\d{3})_CHN(\d{2})_PH0_PLN(\d{4}).tif')
        for f in files:
            m = patternF.fullmatch(f)
            if m:
                newCam = int(m.group(1))
                # print(newCam)
                newFile = 'SPC00_'+tNow+'_ANG000_CM'+str(newCam).zfill(0)+'_CHN'+m.group(2)+'_PH0_PLN'+m.group(3)+'.tif'

                if os.name == 'nt': # windows
                    cmd = 'ren "'+ str(tfNow/f) + '" "' + newFile + '"'                       
                else:
                    cmd = 'mv "'+ str(tfNow/f) + '" "' + str(tfNow/newFile) + '"'
                threading.Thread(target=os.system,args=(cmd,)).start()
                # os.system(cmd)
                # print(cmd)


if __name__ == '__main__':
    # get command line arguments
    args = parse_args()

    if args.flipZ & args.flipCamera:
        exit(f'ERROR: This script does not yet support flipping Z and the camera simultaneously. \nPlease run each command separately to control the order of operations. \nzFlip only flips CM1.')    
    elif args.flipZ: # If requested, flip Z
        run_zFlip(args.input)

        # make sure none of the threads are still running before reporting that you are done
        Nrunning = threading.active_count()
        # print(Nrunning)
        while Nrunning>1:
            sleep(0.05)
            Nrunning = threading.active_count()
            # print(Nrunning)

        print('Done with zFlip')
    elif args.flipCamera:
        run_cameraFlip(args.input)

        # make sure none of the threads are still running before reporting that you are done
        Nrunning = threading.active_count()
        # print(Nrunning)
        while Nrunning>1:
            sleep(0.05)
            Nrunning = threading.active_count()
            # print(Nrunning)

        print('Done with cameraFlip')
    else:
        print('No changes in file names were requested and no files were renamed.')
        print('Use -flipZ or -flipCamera to identify the type of renaming required.')