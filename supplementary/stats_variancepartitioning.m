
% run RSA, comparing pairwise decoding accuracy for 300 face/objects in EEG
% experiment to triplet tasks and ratings data

rerunstats = 0;
load('results/stats_rsa.mat')
timevect = stats.timevect;
modidx = 4:6;
models = stats.modelnames(modidx);
modelnames = stats.modelnames_proper(modidx);

if rerunstats == 0
    load('supplementary/commonality.mat')
else

    %% set up models to test

    mods = stats.modelRDMs(:,modidx);
    % zscore mods
    for m = 1:size(mods,2)
        modsz(:,m) = zscore(mods(:,m));
    end

    % take mean of the group - used for regression
    neuraldat = mean(stats.neural_all,3);

    %% plot models
    figure
    for m = 1:length(modidx)
        subplot(1,length(modidx),m)
        imagesc(squareform(modsz(:,m)))
        title(models(m))
    end

    %% commonality analyses
    % model neural data with behavioural tasks

    % regress three behavioural task results onto neural data and get R2 vals
    % tasks: S = triplet, F = facelike, O = face/object categorisation
    statsSFO = zeros(length(timevect),1);
    statsSF = zeros(length(timevect),1);
    statsSO = zeros(length(timevect),1);
    statsFO = zeros(length(timevect),1);
    statsS = zeros(length(timevect),1);
    statsF = zeros(length(timevect),1);
    statsO = zeros(length(timevect),1);

    order = {'SFO','SF','SO','FO','S','F','O'};

    for t = 1:length(timevect)

        mdlSFO = fitlm(modsz,neuraldat(:,t));
        statsSFO(t) = mdlSFO.Rsquared.Adjusted;
        betas(:,t) = mdlSFO.Coefficients.Estimate;

        mdlSF = fitlm(modsz(:,1:2),neuraldat(:,t));
        statsSF(t) = mdlSF.Rsquared.Adjusted;

        mdlSO = fitlm(modsz(:,[1 3]),neuraldat(:,t));
        statsSO(t) = mdlSO.Rsquared.Adjusted;

        mdlFO = fitlm(modsz(:,[2 3]),neuraldat(:,t));
        statsFO(t) = mdlFO.Rsquared.Adjusted;

        mdlS = fitlm(modsz(:,[1]),neuraldat(:,t));
        statsS(t) = mdlS.Rsquared.Adjusted;

        mdlF = fitlm(modsz(:,[2]),neuraldat(:,t));
        statsF(t) = mdlF.Rsquared.Adjusted;

        mdlO = fitlm(modsz(:,[3]),neuraldat(:,t));
        statsO(t) = mdlO.Rsquared.Adjusted;

    end

    %% calculate unique and common variance explained
    %unique
    s.regress.unique.variables = {'unique spont' 'unique facelike' 'unique faceobj'};
    s.regress.unique.dat(:,1) = statsSFO-statsFO; % s (spontaneous/triplet)
    s.regress.unique.dat(:,2) = statsSFO-statsSO; % f (facelike)
    s.regress.unique.dat(:,3) = statsSFO-statsSF; % o (object categorisation)
    
    %common
    s.regress.common.variables = {'common spont facelike' 'common spont obj' 'common facelike obj' 'common all'};
    s.regress.common.dat(:,1) = statsSO+statsFO-statsO-statsSFO; % SF
    s.regress.common.dat(:,2) = statsSF+statsFO-statsF-statsSFO; % SO
    s.regress.common.dat(:,3) = statsSF+statsSO-statsS-statsSFO; % FO
    s.regress.common.dat(:,4) = statsS+statsF+statsO+statsSFO-statsSF-statsSO-statsFO; % SFO

    % add to s struct
    s.regress.models = {'SFO','SF','SO','FO','S','F','O'};
    s.regress.r2(:,1) = statsSFO;
    s.regress.r2(:,2) = statsSF;
    s.regress.r2(:,3) = statsSO;
    s.regress.r2(:,4) = statsFO;
    s.regress.r2(:,5) = statsS;
    s.regress.r2(:,6) = statsF;
    s.regress.r2(:,7) = statsO;

    s.regress.betas = betas;

    %% run permutations
    fprintf('Computing permutations\n')

    n = size(neuraldat,1);
    rng(1)
    clear statsS* statsF* statsO*
    cc = clock();mm='';

    nperms = 1000;
    for perm = 1:nperms

        permdat = neuraldat(randsample(1:n,n,0),:); % shuffle values in neural RDM

        % regress and get R2 vals
        for t = 1:length(timevect)

            mdlSFO = fitlm(modsz,permdat(:,t));
            statsSFO(t,perm) = mdlSFO.Rsquared.Adjusted;
            permbetas(:,t,perm) = mdlSFO.Coefficients.Estimate;

            mdlSF = fitlm(modsz(:,1:2),permdat(:,t));
            statsSF(t,perm) = mdlSF.Rsquared.Adjusted;

            mdlSO = fitlm(modsz(:,[1 3]),permdat(:,t));
            statsSO(t,perm) = mdlSO.Rsquared.Adjusted;

            mdlFO = fitlm(modsz(:,[2 3]),permdat(:,t));
            statsFO(t,perm) = mdlFO.Rsquared.Adjusted;

            mdlS = fitlm(modsz(:,[1]),permdat(:,t));
            statsS(t,perm) = mdlS.Rsquared.Adjusted;

            mdlF = fitlm(modsz(:,[2]),permdat(:,t));
            statsF(t,perm) = mdlF.Rsquared.Adjusted;

            mdlO = fitlm(modsz(:,[3]),permdat(:,t));
            statsO(t,perm) = mdlO.Rsquared.Adjusted;

        end
        mm = cosmo_show_progress(cc,perm/nperms,sprintf('%i/%i',perm,nperms),mm);

    end

    s.regress.permutations.r2(:,:,1) = statsSFO;
    s.regress.permutations.r2(:,:,2) = statsSF;
    s.regress.permutations.r2(:,:,3) = statsSO;
    s.regress.permutations.r2(:,:,4) = statsFO;
    s.regress.permutations.r2(:,:,5) = statsS;
    s.regress.permutations.r2(:,:,6) = statsF;
    s.regress.permutations.r2(:,:,7) = statsO;

    % calculate unique variance explained
    s.regress.permutations.unique.variables = {'unique spont' 'unique facelike' 'unique faceobj'};
    s.regress.permutations.unique.dat(:,:,1) = s.regress.permutations.r2(:,:,1)-s.regress.permutations.r2(:,:,4); % s (spontaneous/triplet)
    s.regress.permutations.unique.dat(:,:,2) = s.regress.permutations.r2(:,:,1)-s.regress.permutations.r2(:,:,3); % f (facelike)
    s.regress.permutations.unique.dat(:,:,3) = s.regress.permutations.r2(:,:,1)-s.regress.permutations.r2(:,:,2); % o (object categorisation)
    s.regress.permutations.common.variables = {'common spont facelike' 'common spont obj' 'common facelike obj' 'common all'};
    s.regress.permutations.common.dat(:,:,1) = s.regress.permutations.r2(:,:,3)+s.regress.permutations.r2(:,:,4)-s.regress.permutations.r2(:,:,7)-s.regress.permutations.r2(:,:,1); % SF
    s.regress.permutations.common.dat(:,:,2) = s.regress.permutations.r2(:,:,2)+s.regress.permutations.r2(:,:,4)-s.regress.permutations.r2(:,:,6)-s.regress.permutations.r2(:,:,1); % SO
    s.regress.permutations.common.dat(:,:,3) = s.regress.permutations.r2(:,:,2)+s.regress.permutations.r2(:,:,3)-s.regress.permutations.r2(:,:,5)-s.regress.permutations.r2(:,:,1); % FO
    s.regress.permutations.common.dat(:,:,4) = s.regress.permutations.r2(:,:,5)+s.regress.permutations.r2(:,:,6)+s.regress.permutations.r2(:,:,7)+s.regress.permutations.r2(:,:,1)-s.regress.permutations.r2(:,:,2)-s.regress.permutations.r2(:,:,3)-s.regress.permutations.r2(:,:,4); % SFO

    %% sum up
    % permutation descriptions
    perm_max_unique = squeeze(max(s.regress.permutations.unique.dat,[],2));
    perm_ci_unique = prctile(s.regress.permutations.unique.dat,[5 95],2);
    perm_max_common = squeeze(max(s.regress.permutations.common.dat,[],2));
    perm_ci_common = prctile(s.regress.permutations.common.dat,[5 95],2);

    save('commonality.mat','s','perm*','timevect')
end

%% PLOT

cols = tab20(8);

figure(1);clf
set(gcf,'Position',[1525 58 1000 1000])
subplot(2,1,1)

hold on
plot(timevect,timevect*0,'k','HandleVisibility','off')
for x = 1:3
    dat = s.regress.betas(x+1,:); % 1 is intercept
    plot(timevect,dat,'LineWidth',2,'Color',cols(x,:))
    % plot(timevect(~idx),dat(~idx),'.','MarkerSize',5,'Color',[.5 .5 .5],'HandleVisibility','off')
end
legend(modelnames)
set(gca,'FontSize',18)
ylim([-.01 .03])
xlim([-100 1000])
ylabel('Beta')
xlabel('Time (ms)')
set(gca,'FontSize',20)

% overlaid commonality

commonnames = {'Spontaneous/Face-like' 'Spontaneous/Categorisation' 'Face-like/Categorisation' 'All'};

subplot(2,1,2)
hold on
plot(timevect,timevect*0,'k','HandleVisibility','off')
for x = 1:size(s.regress.unique.dat,2)
    dat = s.regress.unique.dat(:,x);
    plot(timevect,dat,'LineWidth',2,'Color',cols(x,:))
end
for x = 1:size(s.regress.common.dat,2)
    dat = s.regress.common.dat(:,x);
    plot(timevect,dat,'LineWidth',2,'Color',cols(x+3,:))
end
legend([strcat('Unique',{' '}, modelnames) strcat('Common',{' '}, commonnames)])
set(gca,'FontSize',20)
ylim([-.01 .26])
xlim([-100 1000])
ylabel('Commonality coefficient')
xlabel('Time (ms)')
set(gca,'FontSize',20)

saveas(gcf,'supplementary/SuppFig3_commonality_combined.png')

%% one by one
figure(3);clf
set(gcf,'Position',[1568 58 2200 1200],'Resize','off')

yl = [-.0005 .01; -.0005 .015; -.008 .26];

for x = 1:size(s.regress.unique.dat,2)
    a=subplot(2,4,x)
    hold on
    dat = s.regress.unique.dat(:,x);
    aboveperm = max(s.regress.permutations.unique.dat(:,:,x),[],2);
    belowperm = min(s.regress.permutations.unique.dat(:,:,x),[],2);
    plot(timevect,dat,'LineWidth',2,'Color',cols(x,:))
    fill([timevect fliplr(timevect)],[aboveperm' fliplr(belowperm')],'k')
    title(strcat('Unique',{' '}, modelnames(x)))
    set(gca,'FontSize',20)
    ylim(yl(x,:))
    xlim([-100 1000])
    ylabel('Commonality coefficient')
    xlabel('Time (ms)')
    set(gca,'FontSize',18)
    a.YAxis.Exponent=0;

end

yl = [-.0008 .01; -.003 .04; -.003 .05; -.004 .095];

n=[5 6 7 4];
for x = 1:size(s.regress.common.dat,2)
    a=subplot(2,4,n(x))
    hold on

    dat = s.regress.common.dat(:,x);
    aboveperm = max(s.regress.permutations.common.dat(:,:,x),[],2);
    belowperm = min(s.regress.permutations.common.dat(:,:,x),[],2);

    plot(timevect,dat,'LineWidth',2,'Color',cols(x+3,:))
    fill([timevect fliplr(timevect)],[aboveperm' fliplr(belowperm')],'k')

    title(strcat('Common',{' '}, commonnames(x)))
    set(gca,'FontSize',20)
    ylim(yl(x,:))
    xlim([-100 1000])
    ylabel('Commonality coefficient')
    xlabel('Time (ms)')
    set(gca,'FontSize',18)
    a.YAxis.Exponent=0;


end
saveas(gcf,'supplementary/SuppFig4_commonality_onebyone.png')


%% use time windows to look at variance partitioning

tw = [90 130; 150 210; 300 350];

for t = 1:size(tw,1)
    tw_unique(:,t) = mean(s.regress.unique.dat(find(timevect>=tw(t,1)&timevect<=tw(t,2)),:),1);
    tw_common(:,t) = mean(s.regress.common.dat(find(timevect>=tw(t,1)&timevect<=tw(t,2)),:));
end

var_all = [tw_unique; tw_common];