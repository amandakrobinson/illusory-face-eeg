
%% plot RDMs from ratings data and triplet data

% add paths
addpath('~/Dropbox/MATLAB/matplotlib/')

% get ordering vectors
load('results/stimorder.mat')

% read data from different tasks
load('results/oddoneoutRDM.mat')
load('results/facelike_ratings.mat')
load('results/faceobjResults.mat');
fo_res = res;
rate = ratingsdat;

%% collate neural data
files = dir('EEG/results/sub-*_decoding.mat');
allneuraldat = [];
for f = 1:length(files)
    load(sprintf('EEG/results/%s',files(f).name))
    allneuraldat(:,:,f) = res.samples(neuridx,:); % reorder to face/illusory/object order
end
neuralRDMs = mean(allneuraldat,3);

timevect = res.a.fdim.values{1};

%% make RDMs

rdms = struct();

% face model (pareidolia = face)
facemod = [repelem(1,200) repelem(2,100)];
rdms.facemodel.RDM = squareform(pdist(facemod','euclidean'));
rdms.facemodel.name = 'Face model';

% object model (pareidolia = object)
objmod = [repelem(1,100) repelem(2,200)];
rdms.objectmodel.RDM = squareform(pdist(objmod','euclidean'));
rdms.objectmodel.name = 'Object model';

% illusory face model (pareidolia = third category)
illmod = [repelem(1,100) repelem(2,100) repelem(3,100)];
illrdm = squareform(pdist(illmod','euclidean'));
illrdm(illrdm>1) = 1;
rdms.illusorymodel.RDM = illrdm;
rdms.illusorymodel.name = 'Illusory face model';

% odd-one-out rdm
rdms.oddoneout.RDM = RDMmean;
rdms.oddoneout.name = 'Spontaneous dissimilarity';

% facelike scores rdm
rdms.facelike.RDM = squareform(pdist(rate.mean','euclidean'));
rdms.facelike.name = 'Face-like ratings';

% face/object categorisation rdm
resp = squeeze((fo_res.faceresp_image(:,1,:)+fo_res.faceresp_image(:,2,:))/2); % mean of short and long presentations
rdms.faceobj.RDM = squareform(pdist(mean(resp,3),'euclidean'));
rdms.faceobj.name = 'Face-object categorisation';

rdms.neural.RDM = neuralRDMs;
rdms.neural.RDMpp = allneuraldat;
rdms.neural.name = 'Neural';
rdms.neural.timevect = timevect;

save('results/rdms_all.mat','rdms','timevect')


%% collate models
models = fieldnames(rdms);
models = models([4:6 1 3 2]);

for m = 1:6
    r = rdms.(models{m}).RDM;
    if r(1,1)~=0
        r(eye(size(r))==1)=0;
    end
    mods(:,m) = squareform(r);
    names{m} = rdms.(models{m}).name;
end

[r,p] = corr(mods,'Type','Spearman');

save('results/rdms_all.mat','rdms','names','mods','r','p')
