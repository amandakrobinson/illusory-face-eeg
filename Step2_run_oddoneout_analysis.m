
%% analyse data from online similarity experiment using triplet task
% read data and construct RDM from odd one out task
% using the order of stimuli that we want (FPO aka faces, pareidolia, objects)

%% load image order for final analysis
load('results/stimorder.mat','stims_FPO');
stims = strcat('stimuli/',stims_FPO(:,1),'_',stims_FPO(:,2),'.jpg'); % filenames in order we want

%% read similarity data from odd one out task

fns = dir('OddOneOut/data/pareidolia_triplets*.csv');

T = [];subnr = 0;
Ta=[];
for f=1:numel(fns)
    fn = fullfile(fns(f).folder,fns(f).name);
    TS = readtable(fn);
    if size(TS,1)>6 % more than 6 lines in the file
        n = strsplit(fns(f).name,'_');
        TS.date(:) = n(5);
        TSdat = TS(strcmp(TS.test_part,'triplet'),:);
        if size(TSdat,1) == 300 % if contains 300 trials (whole experiment), add to group
            subnr = subnr+1;
            TSdat.subjectnr(:) = subnr;
            T = [T; TSdat];
        end
    end
    fprintf('file %i/%i\n',f,numel(fns));
end

%% number stimuli in similarity data to match order of stims we want (FPO)
[~,T.stim0number]=ismember(T.stim0,stims);
[~,T.stim1number]=ismember(T.stim1,stims);
[~,T.stim2number]=ismember(T.stim2,stims);

% remove any trials where two of the same stimuli were presented
idx = find(T.stim0number==T.stim1number|...
    T.stim0number==T.stim2number|...
    T.stim1number==T.stim2number);
T = T(setdiff(1:height(T),idx),:);

subjs = unique(T.subjectnr);
ntrials = zeros(length(subjs),1);
for s = 1:length(subjs)
    ntrials(s) = length(find(T.subjectnr==subjs(s)));
    stims = table2cell(T(T.subjectnr==subjs(s),17:19));
    nstim(s) = length(unique(stims));
    datecompleted(s) = unique(T(T.subjectnr==subjs(s),:).date);
end

fprintf('There are %d subjects and %d total trials\n',length(subjs),height(T));
fprintf('Median trials per subject is %d (range %d to %d)\n',median(ntrials),min(ntrials),max(ntrials))

%% create RDM (ordered as FPO)
fprintf('create RDM\n')
allcombs = [T.stim0number T.stim1number T.stim2number];
choice = T.button_pressed;
RDMsum = zeros(length(stims));
RDMcounts = zeros(length(stims));
for i=1:numel(choice)
    % for every choice, add 1 to the similarity of the two items that were
    % not the odd-one-out (three choices were coded as 0, 1, 2)
    v = allcombs(i,(0:2)~=choice(i));
    RDMsum(v(1),v(2)) = RDMsum(v(1),v(2))+1;
    RDMsum(v(2),v(1)) = RDMsum(v(2),v(1))+1;
    % add 1 to the counts of all items compared, to compute the mean later
    for v = combnk(allcombs(i,:),2)'
        RDMcounts(v(1),v(2)) = RDMcounts(v(1),v(2))+1;
        RDMcounts(v(2),v(1)) = RDMcounts(v(2),v(1))+1;
    end
end

RDMmean = 1 - RDMsum./RDMcounts;

save('results/oddoneoutRDM.mat','RDMmean')

%% plot histogram of counts
f=figure(1);clf;
f.Position = [f.Position(1:2) 1000 400];

tbl=tabulate(squareform(RDMcounts));
figure(1);

subplot(1,2,1)
bar(tbl(:,1),tbl(:,2))
title('RDM cell counts')
xlabel('Number of participants per cell')
ylabel('Number of RDM cells')

subplot(1,2,2)
bar(tbl(:,1),tbl(:,3))
title('RDM cell percentages')
xlabel('Number of participants per cell')
ylabel('Percent of RDM cells')

fn = 'figures/oddoneout_rdmcounts';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');


%% embedding
rng(2)
fprintf('create embedding\n')

Y = RDMmean;
Y(eye(size(Y))==1)=0;
X1 = mdscale(Y,2,'Start','random','Criterion','metricstress','Replicates',10);

%% plot similarity data

nsub = numel(unique(T.subjectnr));
rdm = RDMmean;
imAlpha=ones(size(rdm));
imAlpha(isnan(rdm))=0;

f=figure(2);clf;
f.Position = [f.Position(1:2) 1902 879];

a=subplot(1,3,1);
imagesc(rdm,'AlphaData',imAlpha);
axis square
a.YDir='normal';
colorbar
title(sprintf('RDM (n=%i)',nsub))
colormap plasma

a=subplot(1,3,2);
hold on
X=X1;
aw=range(X(:))*.025;
axis equal
axis square
imrange = 1:360;
plot(X(:,1),X(:,2),'.')
for i=1:length(stims)
    IM = imread(stims{i});
    IM = flipud(IM);
    if size(IM,3)==1
        IM = repmat(IM,1,1,3);
    end
    
    image('XData',X(i,1)+aw*[-1 1],'YData',X(i,2)+aw*[-1 1],'CData',IM(imrange,imrange,1:3))
end
a.XTick = [];
a.YTick = [];
title(sprintf('2-dim embedding of triplet data: %d participants',nsub))

% colour-code different categories and plot MDS
cols = viridis(4);
a=subplot(1,3,3);
hold on
X=X1;
axis equal
axis square
mark = {'x' '+' 'o'};
for i=1:3
    idx = (i-1)*100+1;
    plot(X(idx:(idx+99),1),X(idx:(idx+99),2),mark{i},'Color',cols(i,:))
end
legend({'faces' 'illusory faces' 'objects'});
a.XTick = [];
a.YTick = [];
title('2-dim embedding of triplet data (mdscale-metricstress)')

figure(2)
fn = 'figures/similarity_online';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');


%% embedding bigger
f=figure(3);clf;
f.Position = [84 87 1823 1248];
a=subplot(1,1,1);
hold on
X=X1;
aw=range(X(:))*.03;
axis equal
axis square
imrange = 1:360;
plot(X(:,1),X(:,2),'.')
for i=1:length(stims)
    IM = imread(stims{i});
    IM = flipud(IM);
    if size(IM,3)==1
        IM = repmat(IM,1,1,3);
    end
    
    image('XData',X(i,1)+aw*[-1 1],'YData',X(i,2)+aw*[-1 1],'CData',IM(imrange,imrange,1:3))
end
axis square
a.XTick = [];
a.YTick = [];
title(sprintf('2-dim embedding of triplet data: %d participants',nsub))

fn = 'figures/similarity_online_bigger';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');

%% get countable matrix
mask = tril(ones(300,300),-1);
un = mask.*RDMcounts; % make asymmetric matrix
uncounts = un+triu(ones(300,300))*70; % give one side of matrix huge values

% ROUND1
% %% after n=328 - get missing pairs ie cells with zero data = 67 pairs
% [i,j] = find(uncounts==0);
% missingpairs = [stims(i) stims(j)];
% nmissing = table(missingpairs,i,j);
% writetable(nmissing,'missingpairs.csv');
% 
% % after n=328, get pairs with too much data ie more than 15 data points = 68 pairs
% [k,l] = find(uncounts>15&uncounts<70);
% excesspairs = [stims(k) stims(l)];
% nexcesspairs = table(excesspairs,k,l);
% writetable(nexcesspairs,'excesspairs.csv');

% tested five people with this

% ROUND2
% % after n=333 - get RDM pairs with only one sample = 372 pairs
% [i,j] = find(uncounts<2);
% missingpairs = [stims(i)' stims(j)'];
% nmissing = table(missingpairs,i,j);
% writetable(nmissing,'lowpairstoinclude.csv');
% 
% % after n=333, get pairs with too much data ie >13 data points s 397 pairs
% [k,l] = find(uncounts>13&uncounts<70);
% excesspairs = [stims(k)' stims(l)'];
% nexcesspairs = table(excesspairs,k,l);
% writetable(nexcesspairs,'highpairstoexclude.csv');

% tested five people with this
