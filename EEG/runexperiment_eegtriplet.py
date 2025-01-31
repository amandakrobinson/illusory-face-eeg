#!/usr/bin/env python3, psychopy 2022
# -*- coding: utf-8 -*-
"""
Created on Tuesday 17 Jan 2023

@author: uqarobi7

EEG experiment to understand neural responses to faces, illusory faces and matched objects, 
and how these relate to perceptual experience from odd-one-out task

Last modified by: uqarobi7
Last modified time: 20 March 2023

"""

# IMPORT NECESSARY TOOLBOXES
from psychopy import core, event, visual, gui, parallel
import random,sys,json,requests,os,itertools
from glob import glob
import pandas as pd
import numpy as np


environment = 'home' # lab or home or work

if environment == 'lab':
    monitor_name = 'ASUS'#'workdesk'#'home'
    refreshrate = 120
elif environment == 'home':
    monitor_name = 'home'
    refreshrate = 60
elif environment == 'work':
    monitor_name = 'workdesk'
    refreshrate = 60


#DEBUGGING PROTOCOLS
debug_testsubject = 0 if environment == 'lab' else 1
debug_usedummytriggers = 0 if environment == 'lab' else 1
debug_windowedmode = 0
debug_onesequence = 0 if environment == 'lab' else 1
#------------------------------------

# number of stimulus repeats throughout experiment
nrepeats = 1 if debug_onesequence else 35
nseq = 2 # number of sequences to make from one full set of stimuli

# stim details
stimsize = 4 #size of stim
fixsize = 0.5

stimuli = sorted(glob('stimuli/*.jpg'))
print(stimuli)

nstimuli = len(stimuli)
stimnum = list(range(nstimuli))

if debug_testsubject:
    subjectnr = 0
else:
    # Get subject info
    subject_info = {'Subject number (update participants.tsv)':''}
    if not gui.DlgFromDict(subject_info,title='Enter subject info (update participants.tsv):').OK:
        print('User hit cancel at subject information')
        exit()
    try:
        subjectnr = int(subject_info['Subject number (update participants.tsv)'])
    except:
        raise

# files to save
outfn = 'sub-%02i_task-faceobj_events.csv'%subjectnr
if not debug_testsubject and os.path.exists(outfn):
    raise Exception('%s exists'%outfn)

random.seed(subjectnr)

# timing (ms)
fixationduration = .5 - .5/refreshrate
stimduration = .133 - .5/refreshrate
isiduration = .2666 - .5/refreshrate

# triggers
trigger_stimon = 1
trigger_stimoff = 2
trigger_response = 5
trigger_sequencestart = 3
trigger_duration = 0.005
trigger_port = 0xD050 #qbi

#----- MAKE TRIAL LIST -----------------------------------------------------
# all stimuli are displayed in the centre (40 sequences)
eventlist = pd.DataFrame()

seq_num=-1
seqnums = [(j % nseq) + 1 for j in range(nstimuli)] # random vector of length nstimuli with nseq unique values
for i in range(nrepeats): 
    stream = random.sample(range(nstimuli),nstimuli)
    seqs = [seq_num + seqnums[j] for j in range(nstimuli)] # add seq_num to each element of seqnumss
    seqs = random.sample(seqs,nstimuli)
    for (x1,x2) in enumerate(stream):
        eventlist=eventlist.append(pd.DataFrame([[seqs[x1],x1,x2]], columns=['sequencenumber','presentationnumber','stim']), ignore_index=1)
    seq_num = max(seqs)
    print('stream %i/%i'%(seq_num,nrepeats*nseq))

#eventlist = eventlist.groupby("sequencenumber").sample(frac = 1).reset_index(drop = True) #shuffle the trials within each sequence
eventlist["istarget"] = np.zeros([len(eventlist),1]) #set targets to zeros
neweventlist=pd.DataFrame()
for x in np.unique(eventlist.sequencenumber):
    idx = eventlist.sequencenumber==x
    e = eventlist[idx]
    
    t = [0 for x in range(len(e))] # istarget
    ntargets = random.randint(3,6) #add 3-6 targets in each 150 image stream
    targetpos=[1, 1]
    seqidx = [i for i,j in enumerate(e.sequencenumber) if j==x]
    this_range = [min(seqidx)+10, max(seqidx)-10] # can't appear in first ten or last ten images of sequence
    while len(targetpos)>1 and any(np.diff(targetpos)<10):
        targetpos = sorted(random.sample(range(this_range[0],this_range[1]),ntargets))
    for p in targetpos:
        t[p]=1
    print(f"Number of targets in sequence {x}: {sum(t)}")
    e["istarget"] = t
    neweventlist=neweventlist.append(e, ignore_index=1)
    
#Save the eventlist to a csv before the experiment starts
eventlist=neweventlist
def writeout(eventlist):
    with open(outfn,'w') as out:
        eventlist.to_csv(out,index_label='eventnumber')

writeout(eventlist)

# =============================================================================
# %% START
# =============================================================================

if debug_windowedmode:
    win=visual.Window([1000,1200],units='deg',color=(-.1, -.1, -.1)) # was units='pix'
else:
    win=visual.Window(units='deg',fullscr=True,monitor=monitor_name)

mouse = event.Mouse(visible=False)

filesep='/'
if sys.platform == 'win32':
    filesep='\\'

#---- set up textures -----
fixation = visual.GratingStim(win, tex=None, mask='gauss', sf=0, size=fixsize,
    name='fixation', autoLog=False, color='black')
progresstext = visual.TextStim(win,text='',pos=(0,6),name='progresstext')

sequencestarttext = visual.TextStim(win,height=.8,text='Press any key to start the sequence\nPress space when you see a red star in the centre',pos=(0,4),name='sequencestarttext')

stimtex=[]
for (i,y) in enumerate(stimuli):
    stimtex.append(visual.ImageStim(win,y,size=stimsize,name=y.split(filesep)[1]))

targetstimtex = visual.GratingStim(win, tex=None, mask='gauss', sf=0, size=fixsize,
    name='target', autoLog=False, color='red')

print(stimtex)
print("all_stimtex",len(stimtex))

def send_dummy_trigger(trigger_value):
    core.wait(trigger_duration)

def send_real_trigger(trigger_value):
    trigger_port.setData(trigger_value)
    core.wait(trigger_duration)
    trigger_port.setData(0)

if debug_usedummytriggers:
    sendtrigger = send_dummy_trigger
else:
    trigger_port = parallel.ParallelPort(address=trigger_port)
    trigger_port.setData(0)
    sendtrigger = send_real_trigger

nevents = len(eventlist)
nsequences = eventlist['sequencenumber'].iloc[-1]+1
sequencenumber = -1
for eventnr in range(len(eventlist)):
    first = eventlist['sequencenumber'].iloc[eventnr]>sequencenumber
    if first:
        
        writeout(eventlist)
        sequencenumber = eventlist['sequencenumber'].iloc[eventnr]
        last_target = -99
 
        progresstext.text = '%i / %i'%(1+sequencenumber,nsequences)
        progresstext.draw()
        sequencestarttext.draw()
        fixation.draw()
        win.flip()
        k=event.waitKeys(modifiers=False, timeStamped=True)
        if k[0][0]=='q':
            raise Exception('User pressed q')
        fixation.draw()
        time_fixon = win.flip()
        sendtrigger(trigger_sequencestart)
        while core.getTime() < time_fixon + fixationduration:pass
    
    response=0
    rt=0
    fixation.draw()
    stimname=''

    #Stimulus display    
    if eventlist['stim'].iloc[eventnr]>-1:
        #identify the stimulus
        stim = stimtex[eventlist['stim'].iloc[eventnr]]
        #draw in the centre location
        stim.pos = (0,0)
        stim.draw()
        stimname = stim.name
        fixation.draw()

    time_stimon=win.flip() # show display
    sendtrigger(trigger_stimon)
    
    fixation.draw()
    if eventlist["istarget"].iloc[eventnr]==1:
        #it's a target trial: 
        #draw the target fixation
        targetstimtex.draw()
        
    while core.getTime() < time_stimon + stimduration:pass
    
    # flip for ISI
    time_stimoff=win.flip()
    sendtrigger(trigger_stimoff)

    if eventlist['istarget'].iloc[eventnr]:
        last_target=time_stimoff
        
    correct=0
    k=event.getKeys(keyList='sdq', modifiers=False, timeStamped=True)
    if k:
        response=k[0][0]
        rt=k[0][1]
        if response=='q':
            raise Exception('User pressed q')
        else:
            response=1
        correct = rt-last_target < 1
    
    eventlist.at[eventnr, 'stimname'] = stimname
    eventlist.at[eventnr, 'response'] = int(response)
    eventlist.at[eventnr, 'rt'] = rt-last_target if correct else 0
    eventlist.at[eventnr, 'correct'] = int(correct)
    eventlist.at[eventnr, 'time_stimon'] = time_stimon
    eventlist.at[eventnr, 'time_stimoff'] = time_stimoff
    eventlist.at[eventnr, 'stimdur'] = time_stimoff-time_stimon
    
    while core.getTime() < time_stimon + isiduration:pass

core.wait(1)
fixation.draw()
time_stimoff=win.flip()
writeout(eventlist)
progresstext.text = 'Experiment finished!'
progresstext.draw()
win.flip()
core.wait(1)
win.close()
exit()


