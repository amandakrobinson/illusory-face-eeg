function run_decoding(subjectnr)

%%
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
outfn = sprintf('results/sub-%02i_decoding.mat',subjectnr);

%% decode
ds.sa.blocknum = repelem(1:35,300)';
ds.sa.chunks = ds.sa.blocknum;
nh = cosmo_interval_neighborhood(ds,'time','radius',0);
measure = @cosmo_crossvalidation_measure;
ma = {};
ma.classifier = @cosmo_classify_lda;
ma.nproc = nproc;
ma.progress = 0;

ds.sa.targets = ds.sa.stim;

targs = unique(ds.sa.targets);
targcombs = combnk(targs,2);

fprintf('Decoding...\n');

res_cell=cell(size(targcombs,1),1);
cc = clock();mm='';
for t = 1:size(targcombs,1)
    
    dsd = cosmo_slice(ds,ismember(ds.sa.targets,targcombs(t,:)));
    ma.partitions = cosmo_nfold_partitioner(dsd);
    
    res = cosmo_searchlight(dsd,nh,measure,ma);
    res.sa.subject = subjectnr;
    res.sa.pairnum = t;
    res.sa.stim1 = targcombs(t,1);
    res.sa.stim2 = targcombs(t,2);
    res_cell{t} = res;
    mm = cosmo_show_progress(cc,t/size(targcombs,1),sprintf('%i/%i',t,size(targcombs,1)),mm);
end

res = cosmo_stack(res_cell);
save(outfn,'res','-v7.3')
