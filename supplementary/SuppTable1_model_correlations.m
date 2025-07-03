%% tabulate onsets and peaks
load('results/stats_rsa.mat')

corrs = stats.behavioural_correlations;

tasks = unique([corrs(:,1) corrs(:,2)]);
tasks = tasks([6 1 3 2 4 5]);
tasknames = {'Spontaneous dissimilarity','Face-like ratings','Face-object categorization'...
    'Face model' 'Illusory model' 'Object model'};


order = [1 2; 1 3; 2 3; 4 5; 4 6; 5 6; ...
    1 4; 1 5; 1 6; 2 4; 2 5; 2 6; 3 4; 3 5; 3 6];


% construct table
modelcorrs=struct();
for b = 1:size(order,1)
    idx = find(contains(corrs(:,1),tasks{order(b,1)})&contains(corrs(:,2),tasks{order(b,2)}));
    idx2 = find(contains(corrs(:,2),tasks{order(b,1)})&contains(corrs(:,1),tasks{order(b,2)}));
    idx=[idx idx2];
    modelcorrs.model1{b,1} = tasknames{order(b,1)};
    modelcorrs.model2{b,1} = tasknames{order(b,2)};
    modelcorrs.SpearmanCorrelation(b,1) = corrs{idx,3};
    modelcorrs.pValue(b,1) = corrs{idx,4};
end

dat = struct2table(modelcorrs);
    
