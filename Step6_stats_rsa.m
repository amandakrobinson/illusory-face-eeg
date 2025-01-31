
% run RSA, comparing pairwise decoding accuracy for 300 face/objects in EEG
% experiment to triplet tasks and ratings data
stats=struct();

load('results/rdms_all.mat')
models = fieldnames(rdms);
models = models(~contains(models,'neural'));
allmods = [];
for m = 1:length(models)
    rdm = rdms.(models{m}).RDM;
    rdm(eye(size(rdm))==1)=0;
    allmods(:,m) = squareform(rdm);
    modelnames{m} = rdms.(models{m}).name;
end

%%
modcom = combnk(1:length(models),2);
for m = 1:length(modcom)
    [r_spear(m), pval(m)] = corr(allmods(:,modcom(m,1)),allmods(:,modcom(m,2)),'type','Spearman','rows','complete');
end

stats.behavioural_correlations = [models(modcom) num2cell(r_spear)' num2cell(pval)'];
stats.modelnames = models;
stats.modelnames_proper = modelnames;
stats.modelRDMs = allmods;

%% get stim reordering vector for neural data
load('results/stimorder.mat')
stats.stimorder = stims_FPO;
stats.reorderEEGidx = neuridx;

%% get neural data

files = dir('eeg/results/sub*_decoding.mat');
neural_all=[];
for f= 1:length(files)
    
    fprintf('Getting data for sub-%02i\n',f)
    load(sprintf('eeg/results/%s',files(f).name))
    
    % reorder RDM per timepoint
    neural = res.samples(neuridx,:);
    
    neural_all(:,:,f) = neural;

end
timevect = res.a.fdim.values{1};
stats.timevect = timevect;
stats.neural_all = neural_all;

%% now do neural RSA
% use spearman correlation to correlate neural data with behavioural and toy models
% for each EEG participant, per time point, correlate neural with models

noiseceil=[];corrs=[];
for f= 1:size(neural_all,3)

    % run correlations with each model
    fprintf('Running correlations for sub %02i...\n',f)
    for m = 1:(length(models))
        corrs(:,m,f) =corr(neural_all(:,:,f),allmods(:,m),'type','Spearman');
    end

    % correlate with rest of group - noise ceiling
    for t= 1:length(timevect)
        noiseceil(:,t,f) = corr(neural_all(:,t,f),mean(neural_all(:,t,setdiff(1:20,f)),3),'type','Spearman');
    end

end
fprintf('Correlations done!\n')

stats.corrs = corrs;
stats.noiseceiling = noiseceil;

save('results/stats_rsa.mat','stats')

%% now do stats

for m = 1:length(models)

    fprintf('Running stats for model %s\n',models{m})
    
    % correlations
    c = squeeze(corrs(:,m,:));
    s=struct();
    s.mu_all = c;
    s.mu = mean(c,2);
    s.se = std(c,[],2)./sqrt(size(c,2));
    s.bf = bayesfactor_R_wrapper(s.mu_all,'returnindex',2,'verbose',false,'args','mu=0,rscale="medium",nullInterval=c(-Inf,0.5)');

    stats.(models{m}).corrs = s;

end
fprintf('Stats done!\n')

save('results/stats_rsa.mat','stats')


%% now diff stats
modcomps = combnk(4:6,2);

for m = 1:length(modcomps)

    fprintf('Running stats for model %s versus %s\n',models{modcomps(m,1)},models{modcomps(m,2)})
    
    % correlations
    c = squeeze(corrs(:,modcomps(m,1),:)-corrs(:,modcomps(m,2),:));
    s=struct();
    s.mu_all = c;
    s.mu = mean(c,2);
    s.se = std(c,[],2)./sqrt(size(c,2));
    s.bf = bayesfactor_R_wrapper(s.mu_all,'returnindex',2,'verbose',false,'args','mu=0,rscale="medium",nullInterval=c(-0.5,0.5)');

    stats.diffs.(sprintf('%s_%s',models{modcomps(m,1)},models{modcomps(m,2)})) = s;

end
fprintf('Stats done!\n')

save('results/stats_rsa.mat','stats')