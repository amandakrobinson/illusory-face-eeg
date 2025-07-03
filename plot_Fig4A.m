
load('results/stats_rsa.mat')
neural = mean(stats.neural_all,3);
allrsastats = stats;

load('results/stats_rsa_subsets.mat')
timevect=stats.timevect;

subset = stats.subsetmods_names{1};

%% plot task RDMs just for illusory vs non-face object pairs

figure(2);clf;
set(gcf,'Position',[1 1 1400 800])
a=subplot(2,3,1)
rdm = zeros(300,300);
for n = 1:100
    rdm(100+n,200+n) = 1;
    rdm(200+n,100+n) = 1;
end
imagesc(rdm(201:300,101:200))
axis square
% axis off
a.XTickLabel ='';
a.YTickLabel ='';
a.YDir='normal';
colormap plasma
ylabel('Non-face objects')
xlabel('Illusory faces')
set(gca,'FontSize',20)


a=subplot(2,3,2)
tw = [90 130];
neuraltw = squareform(mean(neural(:,timevect>=tw(1)&timevect<=tw(2)),2));
rdm = neuraltw(201:300,101:200);
imagesc(rdm,[.5 .65])
axis square
% axis off
a.YDir='normal';
a.XTickLabel ='';
a.YTickLabel ='';
colormap plasma
ylabel('Non-face objects')
xlabel('Illusory faces')
set(gca,'FontSize',20)
title('EEG 90-130 ms')

a=subplot(2,3,3)
tw = [150 210];
neuraltw = squareform(mean(neural(:,timevect>=tw(1)&timevect<=tw(2)),2));
rdm = neuraltw;
imagesc(rdm(201:300,101:200),[.5 .65])
axis square
% axis off
a.YDir='normal';
a.XTickLabel ='';
a.YTickLabel ='';
colormap plasma
ylabel('Non-face objects')
xlabel('Illusory faces')
set(gca,'FontSize',20)
title('EEG 150-210 ms')



modnum = 4:6;
modnames = allrsastats.modelnames_proper(modnum);


for m = 1:3
    a=subplot(2,3,m+3);
    rdm = squareform(allrsastats.modelRDMs(:,modnum(m)));
    rdm = rdm(201:300,101:200);
    imagesc(rdm)
    axis square
    % axis off
    a.YDir='normal';
    a.XTickLabel ='';
    a.YTickLabel ='';
    colormap plasma
    set(gca,'FontSize',20)
    xlabel('Illusory faces')
    ylabel('Non-face objects')
    title(modnames(m))

end
saveas(gcf,'../figures/Figure4A_rdms_matchedobjects.png')


