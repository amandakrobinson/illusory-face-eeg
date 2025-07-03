
load('results/stats_rsa_subsets.mat')

subset = stats.subsetmods_names{1};

%% plot
co = tab10(6);
timevect=stats.timevect;

figure(1);clf
set(gcf,'Position',[1 1 650 900])
sp=subplot(2,1,1)
hold on
plot(timevect,timevect*0,'k','HandleVisibility','off')

for m = 1:3
    %% plot correlations
    mods = stats.modelnames(m);
    s = stats.(subset).(mods{1}).corrs;
    mu = s.mu;
    se = s.se;

    fill([timevect fliplr(timevect)],[mu'+se' fliplr(mu'-se')],co(m,:),'FaceAlpha',.1,'EdgeAlpha',0,'HandleVisibility','off')
    hold on
    plot(timevect,mu,'LineWidth',2,'Color',co(m,:))

end

xlim([-100 600])
ylim([-.1 .3])
legend(stats.modelnames_proper(1:3),'Box','off')
set(gca,'FontSize',18)
% title('Nested pairs: neural-behaviour correlations')
ylabel('Spearman correlation')
xlabel('Time (ms)')


%% plot bayes factors
for m= 1:3
    mods = stats.modelnames(m);
    s = stats.(subset).(mods{1}).corrs;

    a=subplot(6,1,3+m);hold on
    a.FontSize=20;
    plot(timevect,1+0*timevect,'k-');
    co3 = [.5 .5 .5;1 1 1;co(m,:)];
    idx = [s.bf<1/10,1/10<s.bf & s.bf<10,s.bf>10]';
    for i=1:3
        x = timevect(idx(i,:));
        y = s.bf(idx(i,:));
        if ~isempty(x)
            stem(x,y,'Marker','o','Color',.6*[1 1 1],'BaseValue',1,'MarkerSize',5,'MarkerFaceColor',co3(i,:));%,'Clipping','off');
            plot(x,y,'o','Color',.6*[1 1 1],'MarkerSize',5,'MarkerFaceColor',co3(i,:));%,'Clipping','off');
        end
    end
    a.YScale='log';
    ylim([10.^-5 10.^10])
    a.YTick = 10.^([-5 0 5 10]);
    xlim([-100 600])
    ylabel('BF')
    xlabel('Time (ms)')

    text(150,5e5,stats.modelnames_proper{m},'Fontsize',20,'Color',co(m,:))

end

%% save
fn = '../figures/Figure4B_nested_rsa';
print(gcf,'-dpng','-r300',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
