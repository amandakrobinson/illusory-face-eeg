function run_category_decoding(subjectnr)

%% run category decoding: faces vs objects vs pareidolia
% always generalise to new exemplar - true category decoding

%% set up
if ismac
    if isempty(which('cosmo_wtf'))
        addpath('~/CoSMoMVPA/mvpa')
    end
    nproc = 2;
else %on HPC
    addpath('../CoSMoMVPA/mvpa');
    % start cluster, give it a unique directory
    % starting a pool can fail when 2 procs are requesting simultaneous
    % thus try again after a second until success
    pool=[];
    while isempty(pool)
        try
            pc = parcluster('local');
            pc.JobStorageLocation=tempdir;
            pool=parpool(pc);
        catch err
            disp(err)
            delete(gcp('nocreate'));
            pause(1)
        end
    end
    nproc=cosmo_parallel_get_nproc_available();
end

%% load data
fn = sprintf('data/derivatives/cosmomvpa/sub-%02i_task-faceobj_cosmomvpa.mat',subjectnr);
fprintf('loading %s\n',fn);tic
load(fn,'ds')
fprintf('loading data finished in %i seconds\n',ceil(toc))
outfn = sprintf('results/sub-%02i_decoding_category_acc.mat',subjectnr);

%% add important variables
ds.sa.blocknum = repelem(1:35,300)';
ds.sa.chunks = ds.sa.blocknum;

newA = cellfun(@(x) strsplit(x, '_'), ds.sa.stimname, 'UniformOutput', false);
newA = vertcat(newA{:}); % To remove nesting of cell array newA
ds.sa.category = newA(:,1);
ds.sa.catnum = zeros(size(ds.sa.category));

ds.sa.catnum(ismember(ds.sa.category,'face')) = 1;
ds.sa.catnum(ismember(ds.sa.category,'pareidolia')) = 2;
ds.sa.catnum(ismember(ds.sa.category,'object')) = 3;

%% decoding parameters
nh = cosmo_interval_neighborhood(ds,'time','radius',0);
measure = @cosmo_crossvalidation_measure;
ma = {};
ma.classifier = @cosmo_classify_lda;
ma.nproc = nproc;
ma.output = 'accuracy';

%% decode
ds.sa.targets = ds.sa.catnum;
targcombs = combnk(unique(ds.sa.targets),2);

res_cell={};
for t = 1:size(targcombs,1)

    dsd = cosmo_slice(ds,ismember(ds.sa.targets,targcombs(t,:)));

    % make partitions
    uc = unique(dsd.sa.chunks); % sequences
    ue = unique(dsd.sa.stim); % which stims to leave out

    p = repelem(uc,length(ue),1); % chunk to leave out (one chunk per sequence x stim num)
    e = repmat(ue,length(uc),1); % stim num to leave out

    ma.partitions = struct();
    ma.partitions.train_indices = cell(1,length(p));
    ma.partitions.test_indices = cell(1,length(p));
    for i=1:length(p)
        idx1 = dsd.sa.chunks==p(i,:); % chunk to leave out
        idx2 = dsd.sa.stim==e(i); % exemplar to leave out from class 1
        ma.partitions.train_indices{i} = find(~idx1 & ~idx2);
        ma.partitions.test_indices{i} = find(idx1 & idx2);
    end

    ma.partitions = cosmo_balance_partitions(ma.partitions,dsd,'balance_test',false);

    % decode
    res = cosmo_searchlight(dsd,nh,measure,ma);
    res.sa.subject = subjectnr;
    res.sa.cat1 = unique(dsd.sa.category(dsd.sa.catnum==targcombs(t,1)));
    res.sa.cat2 = unique(dsd.sa.category(dsd.sa.catnum==targcombs(t,2)));
    res.sa.targcomb = t;
    res_cell{t} = res;
end

res = cosmo_stack(res_cell);
timevect = res.a.fdim.values{1};
save(outfn,'res','-v7.3')
