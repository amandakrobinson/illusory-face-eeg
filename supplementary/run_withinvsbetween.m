
load('results/stats_rsa.mat')

%% get triplet RDM

rdm = squareform(stats.modelRDMs(:,ismember(stats.modelnames,'oddoneout')));

between = rdm(101:200,201:300);
bw = between(:);

withinill = squareform(rdm(101:200,101:200));
withinobj = squareform(rdm(201:300,201:300));

mu = [mean(withinobj) mean(withinill) mean(bw)];
se = [std(withinobj)/sqrt(length(withinobj)) std(withinill)/sqrt(length(withinill)) std(bw)/sqrt(length(bw))];



%% plot
figure(1);clf;
set(gcf,'Position',[1 371 1480 430])

ax=subplot(1,3,1)
imagesc((rdm))
axis square
ax.YDir='normal';
colormap(ax,plasma)
xlim([1 300])
ylim([1 300])
ax.XTick = [50:100:250];
ax.XTickLabel = {'Human\newlinefaces' 'Illusory\newlinefaces' 'Non-face\newlineobjects'};
ax.YTick = [50:100:250];
ax.YTickLabel = {'Human\newlinefaces' 'Illusory\newlinefaces' 'Non-face\newlineobjects'};
set(ax,'FontSize',18)

a=subplot(1,3,2)
model = zeros(300,300);
model(101:200,201:300) = 1;
model(101:200,101:200) = 2;
model(201:300,201:300) = 3;
model = model - diag(diag(model));
imagesc(triu(model))
axis square
a.YDir='normal';
xlim([1 300])
ylim([1 300])
a.XTick = [50:100:250];
a.XTickLabel = {'Human\newlinefaces' 'Illusory\newlinefaces' 'Non-face\newlineobjects'};
a.YTick = [50:100:250];
a.YTickLabel = {'Human\newlinefaces' 'Illusory\newlinefaces' 'Non-face\newlineobjects'};
set(a,'FontSize',18)

colormap(a,tab10(4))
cb1=colorbar('Ticks',[3/8*3 5/8*3 7/8*3],'TickLabels',{'Between' 'Within\newlineillusory' 'Within\newlineobject'});
cb1.Position = [cb1.Position(1)+.05 cb1.Position(2:4)];
cb1.FontSize = 15;
cb1.Limits = [3/4 3];

% plot mean within vs between distance
cols = tab10(4);
cols = flipud(cols);

s=subplot(1,3,3)
set(s,'FontSize',18)
set(s,'Position',[s.Position(1)+.08 s.Position(2)+.02 s.Position(3) s.Position(4)-.02])
hold on

for a = 1:3
    bar(a,mu(a),'FaceColor',cols(a,:))
end
errorbar(mu,se,'.')
xlim([0.2 3.8])
set(gca,'XTickLabel',{'Within\newlineobject' 'Within\newlineillusory' 'Between'})
ylabel('Dissimilarity')

annotation('textbox','Units','Normalized','Position', [.07 .89 .05 .05],...
    'LineStyle','none','String','A',...
    'FontSize',30,'VerticalAlignment','middle','HorizontalAlignment','left');
annotation('textbox','Units','Normalized','Position', [.35 .89 .05 .05],...
    'LineStyle','none','String','B',...
    'FontSize',30,'VerticalAlignment','middle','HorizontalAlignment','left');

annotation('textbox','Units','Normalized','Position', [.7 .89 .05 .05],...
    'LineStyle','none','String','C',...
    'FontSize',30,'VerticalAlignment','middle','HorizontalAlignment','left');



saveas(gcf,'supplementary/SuppFig1_withinbetweentriplet.png')

%% stats to compare
% 
% [~,p(1),~,stats] = ttest2(withinill,bw);
% t(1) = stats.tstat;
% 
% [~,p(2),~,stats] = ttest2(withinobj,bw);
% t(2) = stats.tstat;
% 
% [~,p(3),~,stats] = ttest2(withinill,withinobj);
% t(3) = stats.tstat;

within = [withinill withinobj];

[p,h,stats] = ranksum(within,bw)