
addpath('~/Dropbox/MATLAB/CoSMoMVPA/mvpa')

% run RSA, comparing pairwise decoding accuracy for nested pairs of illusory faces/objects in EEG
% experiment to triplet task and ratings data
stats=struct();

load('results/rdms_all.mat')
models = fieldnames(rdms);
models = models(4:6);
allmods = [];modelnames={};
x=0;
for m = 1:length(models)
    x=x+1;
    rdm = rdms.(models{m}).RDM;
    rdm(eye(size(rdm))==1)=0;
    allmods(:,x) = squareform(rdm);
    modelnames{x} = rdms.(models{m}).name;
end

stats.modelnames = models;
stats.modelnames_proper = modelnames;
stats.modelRDMs = allmods;

%% models of subsetted RDMs - nested pairs and individual categories
% use spearman correlation to correlate neural data with 3 behavioural models
% for each EEG participant, per time point, correlate neural with models

subsetidx = zeros(length(allmods),4);
stats.subsetmods_names = {'nested' 'faceonly' 'illusoryonly' 'objectonly'};

% nested pairs
% use only paired images of pareidolia and objects (100 data points)
nestedidx = zeros(300,300);
for a = 1:100
    nestedidx(100+a,200+a) = 1;
    nestedidx(200+a,100+a) = 1;
end
subsetidx(:,1) = squareform(nestedidx);

categories = {'face' 'illusory' 'object'};
for c = 1:3 % for each category
    m = zeros(300,300);
    startidx = (c-1)*100+1;
    m(startidx:(startidx+99),startidx:(startidx+99)) = 1;
    m(eye(size(m))==1)=0;
    subsetidx(:,c+1) = squareform(m);
end

stats.subsetidx = subsetidx;

%% plot subsets in RDMs

figure
for s = 1:size(subsetidx,2)
    subplot(1,4,s)
    imagesc(squareform(subsetidx(:,s)))
    set(gca,'YDir','normal')
end


%% now do neural-subsetmods correlations

neurPP = rdms.neural.RDMpp;
corrs=zeros(size(neurPP,2),3,4,size(neurPP,3));
for f = 1:size(neurPP,3)

    dat = neurPP(:,:,f);

    fprintf('Running correlations for sub-%02i\n',f)
        
    for m = 1:3 % behavioural models
        for n = 1:size(subsetidx,2) % model subsets
            idx = subsetidx(:,n);
            corrs(:,m,n,f) = corr(dat(idx==1,:),allmods(idx==1,m),'type','Spearman','rows','complete');
        end
    end
end

stats.corrs = corrs;
stats.timevect = rdms.neural.timevect;

save('results/stats_rsa_subsets.mat','stats')

%% now do stats

for m = 1:3 % for each behavioural model

    fprintf('Running stats for model %s\n',models{m})

    %% for each of the subsets
    for n = 1:size(subsetidx,2) % model subsets


        % correlations
        c = squeeze(corrs(:,m,n,:));
        s=struct();
        s.mu_all = c;
        s.mu = mean(c,2);
        s.se = std(c,[],2)./sqrt(size(c,2));
        s.bf = bayesfactor_R_wrapper(s.mu_all,'returnindex',2,'verbose',false,'args','mu=0,rscale="medium",nullInterval=c(-0.5,0.5)');

        stats.(stats.subsetmods_names{n}).(models{m}).corrs = s;

    end
end

save('results/stats_rsa_subsets.mat','stats')

