#!/bin/bash

# unset the DISPLAY variable to avoid coredumps with large numbers of jobs
unset DISPLAY

#Set up your mcr cache location -- Replace <USERNAME> with your username
export MCR_CACHE_ROOT=/scratch/$USER/mcr_cache_root.$LSB_JOBID.$LSB_JOBINDEX

#Now give the path to your matlab executable
exec $* $LSB_JOBINDEX

#Cleanup after the job -- Replace <USERNAME> with your username
rm -rf $MCR_CACHE_ROOT