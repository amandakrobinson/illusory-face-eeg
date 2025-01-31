%% stimulus reordering for analyses
% make "rosetta stone" document for converting alphabetical order of
% stimuli to the order that we want to present everything in
% used to apply same order of stimuli to all experiments - EEG, oddoneout,
% categorisation task and facelike scores.

% the ultimate order of categories we want
catnames = {'face' 'pareidolia' 'object'};

% get stim names in alphabetical order (FOP = face,obj,pare)
filenames = {'face*.jpg','object*.jpg','pare*.jpg'};
files = cellfun(@(x)dir(fullfile('stimuli/',x)),filenames,'UniformOutput',false);
stims_ab = vertcat(files{:});
stimnames = {stims_ab(:).name};
stims_ab = cellfun(@(x) strsplit(x, {'.','_'}), stimnames, 'UniformOutput', false);
stims_ab = vertcat(stims_ab{:});

%% reorder by face, pareidolia, object category
faces = find(contains(stims_ab(:,1),'face'));
parei = find(contains(stims_ab(:,1),'pareidolia'));
objects = find(contains(stims_ab(:,1),'object'));

neworder = [faces; parei; objects];

%% now reorder stimuli to FPO and get indices
stims_FPO = stims_ab(neworder,:); % this is the ultimate order we want

for s = 1:length(stims_FPO)
    stimnames_FPO{s,1} = [stims_FPO{s,1}, stims_FPO{s,2}];
end

% now get idx of alphabetised stims - these are equal/reversed
for s = 1:length(stims_FPO)
    FPOfromAB(s) = find(ismember(stims_ab(:,1),stims_FPO(s,1))&ismember(stims_ab(:,2),stims_FPO(s,2)));
    ABfromFPO(s) = find(ismember(stims_FPO(:,1),stims_ab(s,1))&ismember(stims_FPO(:,2),stims_ab(s,2)));
end

%% now get reordering index for EEG
% eeg pairwise decoding used pairs of stimuli based on original (alphabetical) order of stimuli
% so need to get indexing vector that converts order of 44850 stim pairs to
% the face-illusory-object order

load('eeg/results/sub-01_decoding.mat','res')
dat = readtable('eeg/data/sub-01/eeg/sub-01_task-faceobj_events.csv');

% get order of stimuli in EEG (should be same as stimnames alphabetical: face->obj>pareidolia)
stimnums = unique(dat.stim);
for st = 1:length(stimnums)
    stnum(st) = stimnums(st);
    eegnames(st) = unique(dat.stimname(dat.stim==stnum(st)));
end

% get reordering index
for s = 1:length(stimnames_FPO)
    FPOfromEEG(s) = find(contains(eegnames,stims_FPO(s,1))&contains(eegnames,stims_FPO(s,2)));
end

% reorder unique pairs to FPO
ma = squareform(1:size(res.samples,1));
manew = ma(FPOfromEEG,FPOfromEEG);
neuridx = squareform(manew); % this is the reordering index for pairs

%% collate and save
rosetta = table(stimnames', ABfromFPO',stimnames_FPO,FPOfromAB','VariableNames',{'alphabetical','ABfromFPO','FPO_order','FPOfromAB'});
writetable(rosetta,'results/stimorder_rosetta.csv')

save('results/stimorder.mat','FPOfromAB','stimnames_FPO','stims_FPO','neuridx');
