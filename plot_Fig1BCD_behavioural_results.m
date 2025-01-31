%% plot behavioural results
catnames = {'Human faces' 'Illusory faces' 'Non-face objects'};
cols = viridis(4);

% set up figure
f=figure(2);clf;
f.Position = [f.Position(1:2) 1900 400];
f.Resize = 'off';

% read data from different tasks
%% first: odd-one-out/spontaneous behaviour
load('results/oddoneoutRDM.mat','RDMmean')

rng(2)
fprintf('create embedding\n')

Y = RDMmean;
Y(eye(size(Y))==1)=0;
X1 = mdscale(Y,2,'Start','random','Criterion','metricstress','Replicates',10);

%% plot similarity data
% colour-code different categories and plot MDS

a=subplot(1,3,1);
set(a,'FontSize',24)
hold on
X=X1;
% axis square
mark = {'x' '+' 'o'};
for i=1:3
    idx = (i-1)*100+1;
    plot(X(idx:(idx+99),1),X(idx:(idx+99),2),'.','MarkerSize',30,'Color',cols(i,:))
end
% legend(catnames,'Location','best');
a.XTick = [];
a.YTick = [];
xlabel('Dimension 1')
ylabel('Dimension 2')
set(gca,'LineWidth',2)
xl = get(gca,'XLim');
set(gca,'XLim',[xl(1)-.05 xl(2)+.05])
yl = get(gca,'YLim');
set(gca,'YLim',[yl(1)-.05 yl(2)+.07])
axis equal

labels = cellfun(@(x) strrep(x,' ','\newline'), catnames,'UniformOutput',false);

text(-.45,.47,labels{1},'Color',cols(1,:),'FontSize',20,'HorizontalAlignment','center');
text(.39,-.54,labels{2},'Color',cols(2,:),'FontSize',20,'HorizontalAlignment','center');
text(.54,.58,labels{3},'Color',cols(3,:),'FontSize',20,'HorizontalAlignment','center');


%% second: face-like ratings

load('results/facelike_ratings.mat')
rate = ratingsdat;
clear mu_cat se_cat groupmu_cat

% results per category
cats = {'h' 'p' 'ob'};
for c = 1:length(cats)
    idx = contains(ratingsdat.stim,cats{c});
    mu_cat(c) = mean(rate.mean(idx));
    se_cat(c) = std(rate.mean(idx))/sqrt(length(rate.mean(idx)));
    groupmu_cat(c,:) = mean(rate.alldat(:,idx),2);
end

% faces vs illusory faces
[~,p,~,stats] = ttest(groupmu_cat(2,:),groupmu_cat(1,:))
% objects vs illusory faces
[~,p,~,stats] = ttest(groupmu_cat(2,:),groupmu_cat(3,:))

% illusory faces versus 5
[~,p,~,stats] = ttest(groupmu_cat(2,:),5)

% ratings per item
datm = rate.alldat;
datmu = mean(datm,1);
datse = std(datm,[],1)/sqrt(size(datm,1));

% plot ratings
a=subplot(1,3,2);
set(a,'FontSize',24)
hold on
for i = 1:3
    idx = (i-1)*100+(1:100);
    % plot(idx,datmu(idx),'o','MarkerFaceColor',cols(i,:),'MarkerEdgeColor','none')
    plot(idx,datmu(idx),'.','MarkerSize',30, 'Color',cols(i,:))
    errorbar(idx,datmu(idx),datse(idx),...
        'Color',cols(i,:),'LineStyle','none','CapSize',2,'HandleVisibility','off')
end
set(gca,'XTick',50:100:250)
set(gca,'XTickLabels',labels)


% axis square
% xlabel('Stimulus')
ylabel('Mean Rating')
xlim([1 300])
% title('Face-like ratings')
set(gca,'LineWidth',2)


%% third: face/object categorisation
% load data

load('results/faceobjResults.mat','res')

clear mu_cat se_cat groupmu_cat
% collate results per category
cats = {'face' 'pare' 'ob'};
resp = squeeze((res.faceresp_image(:,1,:)+res.faceresp_image(:,2,:))/2);
for c = 1:length(cats)
    idx = contains(res.images(:,1),cats{c});
    dat = mean(resp(idx,:),1);
    mu_cat(c) = mean(dat);
    se_cat(c) = std(dat)/sqrt(length(dat));
    groupmu_cat(c,:) = dat;
end

% faces vs illusory faces
[~,p,~,stats] = ttest(groupmu_cat(2,:),groupmu_cat(1,:))
% objects vs illusory faces
[~,p,~,stats] = ttest(groupmu_cat(2,:),groupmu_cat(3,:))
% faces vs objects
[~,p,~,stats] = ttest(groupmu_cat(1,:),groupmu_cat(3,:))





mu = mean(resp,2);
se = std(resp,[],2)/sqrt(size(resp,2));

% plot image stuff
a=subplot(1,3,3)
set(a,'FontSize',24)
hold on
for i = 1:3
    idx = (i-1)*100+(1:100);
    plot(idx,mu(idx),'.','Color',cols(i,:),'MarkerSize',30)
    errorbar(idx,mu(idx),se(idx),...
        'Color',cols(i,:),'LineStyle','none','CapSize',2,'HandleVisibility','off')
end
% axis square
% xlabel('Stimulus')
ylabel('Proportion "face" response')
xlim([1 300])
xt=50:100:250;
set(gca,'XTick',xt)
set(gca,'XTickLabel',labels)
set(gca,'LineWidth',2)

%% save
fn = 'figures/Fig1BCD_behavioural_results';
print(gcf,'-dpng','-r300',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
