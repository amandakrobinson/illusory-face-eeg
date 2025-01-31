function run_preprocessing(partid)

% preprocess pareidolia eeg data:
% high pass 0.1hz
% low pass 100hz
% interpolate bad channels
% average rereference
% downsample to 256 hz
% epoch -100 to 1000ms from onset
% convert data to cosmomvpa format


%% eeglab
if isempty(which('eeglab'))
    addpath('~/Dropbox/MATLAB/eeglab2021.1')
end
eeglab

%% cosmomvpa
if isempty(which('cosmo_wtf'))
    addpath('~/Dropbox/MATLAB/CoSMoMVPA/mvpa')
end

%% get files

datapath = 'data';

% check for cosmo file already
if isfile(sprintf('%s/derivatives/cosmomvpa/sub-%02i_task-faceobj_cosmomvpa.mat',datapath,partid))
    fprintf('Cosmo file found for sub-%04i, skipping...\n',partid)
    return
end

% set up file name for preprocessed data
contfn = sprintf('%s/derivatives/eeglab/sub-%02i_task-faceobj.set',datapath,partid);

% check for preprocessed data already
if isfile(contfn)
    fprintf('Using %s\n',contfn)
    EEG_raw = pop_loadset(contfn);
else
    % load EEG file
    EEG_raw = pop_biosig(sprintf('%s/sub-%02i/eeg/sub-%02i_task-faceobj_eeg.bdf',datapath,partid,partid), ...
        'ref',48); % reference to Cz
    EEG_raw = eeg_checkset(EEG_raw);
    
    % chan locations
    EEG_raw =pop_chanedit(EEG_raw, 'lookup','~/Dropbox/MATLAB/eeglab2021.1/plugins/dipfit/standard_BEM/elec/standard_1005.elc');
    
    % high pass filter
    EEG_raw = pop_eegfiltnew(EEG_raw, 0.1,[]);
    
    % low pass filter
    EEG_raw = pop_eegfiltnew(EEG_raw, [],100);
    
    % get/interpolate bad channels
    [~, badidx] = pop_rejchan(EEG_raw, 'elec',[1:47 49:64],'threshold',5,'norm','on','measure','prob');
    EEG_raw = eeg_interp(EEG_raw,badidx);
    EEG_raw = eeg_checkset(EEG_raw);
    
    % average re-reference
    EEG_raw = pop_reref(EEG_raw,1:64,'keepref','on');
    
    % downsample
    EEG_raw = pop_resample( EEG_raw, 256);
    EEG_raw = eeg_checkset(EEG_raw);
    
    % save
    pop_saveset(EEG_raw,contfn);
end

EEG_cont = pop_select(EEG_raw, 'nochannel',{'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});

%% add eventinfo to events
% triggers in data are:
% trigger_pre_fix_cross_on = 3 #when the fixation cross appears
% trigger_image_on = 1 #when the stimulus appears
% trigger_image_off = 2 #when the stimulus disappears

eventsfncsv = sprintf('%s/sub-%02i/eeg/sub-%02i_task-faceobj_events.csv',datapath,partid,partid);
eventsfntsv = sprintf('%s/sub-%02i/eeg/sub-%02i_task-faceobj_events.tsv',datapath,partid,partid);
eventlist = readtable(eventsfncsv);

trig = [EEG_cont.event.edftype];
idx = find(trig==1); 

% make new BIDS-worthy eventlist
onset = vertcat(EEG_cont.event(idx).latency);
duration = zeros(size(onset))+266.66;

neweventlist = [table(onset,duration,'VariableNames',{'onset','duration'}) eventlist];

writetable(neweventlist,'tmp.csv','Delimiter','\t')
movefile('tmp.csv',eventsfntsv)

%% extract onset-aligned epochs
% align to when each stimulus appeared
EEG_epoch = pop_epoch(EEG_cont, {'condition 1'}, [-0.100 1]);
EEG_epoch = eeg_checkset(EEG_epoch);

EEG_epoch = pop_rmbase(EEG_epoch,[-100 0]); % baseline correct to -100ms before onset
EEG_epoch = eeg_checkset(EEG_epoch);

% convert to cosmo
ds = cosmo_flatten(permute(EEG_epoch.data,[3 1 2]),{'chan','time'},{{EEG_epoch.chanlocs.labels},EEG_epoch.times},2);
ds.a.meeg=struct(); %or cosmo thinks it's not a meeg ds
ds.sa = table2struct(eventlist,'ToScalar',true);
cosmo_check_dataset(ds,'meeg');

% save epochs
save(sprintf('%s/derivatives/cosmomvpa/sub-%02i_task-faceobj_cosmomvpa.mat',datapath,partid),'ds')

end