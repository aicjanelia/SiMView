#! /misc/local/python-3.8.2/bin/python3

import argparse
from pathlib import Path
from sys import exit
import xml.etree.ElementTree as ET

"""
Parser for command line arguments
"""
def parse_args():
    parser = argparse.ArgumentParser(description='Changes a BigStitcher XML such that every other channel is assumed to belong to a second illumination arm.')
    parser.add_argument('input', type=Path, help='path to XML')
    args = parser.parse_args()

    if not args.input.is_file():
        exit(f'error: \'%s\' is does not exist or is not a file.' % args.input)

    return args

"""
Use the first timepoint to determine the range of the various file types
"""
def parse_xml(path):

    origXML = ET.parse(path)

    newXML = origXML.getroot()
    ViewSetUps = newXML[1][1] # View parameters are in SequenceDescription, which contains ViewSetups
    # ViewSetUps contains a "ViewSetup" for each channel, and then attributes for the various features

    # Number of cameras to alternative appropriately
    for child in ViewSetUps.findall('Attributes'):
        if child.get('name') == 'angle':
            numCamera = len(child.findall('Angle'))

    # Check assumptions on the viewsetup organization
    child = ViewSetUps.find('ViewSetup')
    if child[3][0].tag != 'illumination':
        exit(f'Illumination information in wrong part of ViewSetup')
    if child[3][1].tag != 'channel':
        exit(f'Channel information in wrong part of ViewSetup')

    # ----- Make the changes to each view set up
    print('Old View Set Up: View ID, Illumination, Channel')
    # Fix the view set ups
    for indx, child in enumerate(ViewSetUps.findall('ViewSetup')):
        illum = child[3][0].text
        ch = child[3][1].text
        
        print(indx, illum, ch) #View ID, illumination, channel
        if (int(ch) % 2): # if an odd numbered channel
            newXML[1][1][indx][3][0].text = str(1) # odd numbered channels are 2nd illumination arm
            newXML[1][1][indx][3][1].text = str(int(ch)-1) # match the corresponding even number channel

        ch = child[3][1].text
        # Now divide by the number of cameras for sensible numbering
        newXML[1][1][indx][3][1].text = str(int(int(ch)/numCamera))

    # Print the new for a comparision
    print('New View Set Up: View ID, Illumination, Channel')
    for indx, child in enumerate(ViewSetUps.findall('ViewSetup')):
        illum = child[3][0].text
        ch = child[3][1].text        
        print(indx, illum, ch) #View ID, illumination, channel

    # ----- Append a new illumination
    # Assumption: illumination is the first Attributes after ViewSetups complete
    # Check assumption
    if newXML[1][1][indx+1].get('name') != 'illumination':
        exit(f'Illumination definition in wrong part of ViewSetups')
    # Add illumination
    newElement = ET.fromstring(b'<Illumination>\n          <id>1</id>\n          <name>1</name>\n        </Illumination>\n      ' )    
    newXML[1][1][indx+1].append(newElement)
    # Note this doesn't quite make the formatting look pretty, but it still works?

    # ----- Clean up the channels
    # Check organization assumption
    if newXML[1][1][indx+2].get('name') != 'channel':
        exit(f'Channel definition in wrong part of ViewSetups')

    print('')
    print('Old Channel Set Up:')
    for child in newXML[1][1][indx+2]:
        print(child.tag,child[0].text,child[1].text)

    for child in newXML[1][1][indx+2]:
        if int(child[0].text) % 2: # If odd numbered channel
            newXML[1][1][indx+2].remove(child)

    print('New Channel Set Up:')
    for child in newXML[1][1][indx+2]:
        child[0].text = str(int(int(child[0].text)/numCamera))
        print(child.tag,child[0].text,child[1].text)

    #Save updated XML
    newName = path.with_name(path.name[0:-4] + '_separateIllum.xml')
    origXML.write(newName)

    print('')

    return newName


if __name__ == '__main__':
    # get command line arguments
    args = parse_args()

    newName = parse_xml(args.input)

    print('XML file conversion complete.')
    print('File saved to ' + str(newName))