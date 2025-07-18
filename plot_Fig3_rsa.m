
load('results/stats_rsa.mat')

%% plot
co = tab10(6);
timevect=stats.timevect;
models1 = 4:6;
models2 = [1 3 2];

nl = stats.lowernoiseceiling;
munl=mean(nl,2)';

figure(1);clf
set(gcf,'Position',[1 1 1200 900])
n=0;nb=0;
for m= 1:2
    %% plot correlations
    b=subplot(2,2,m);hold on;
    if m == 1
        modidx = models1;
        tn = 'EEG-task correlations';
    else
        modidx = models2;
        tn = 'EEG-category correlations';
    end
    mods = stats.modelnames(modidx);
    modnames = stats.modelnames_proper(modidx);

    plot(timevect,timevect*0,'k','HandleVisibility','off')

    % plot noise ceiling
    plot(timevect,munl,'Color',[.5 .5 .5])
    
    % plot neural-model correlations
    hold on
    for t = 1:length(mods)
        n=n+1;
        dat = stats.(mods{t}).corrs;
        mu = dat.mu;
        se = dat.se;

        fill([timevect fliplr(timevect)],[mu'+se' fliplr(mu'-se')],co(n,:),'FaceAlpha',.1,'EdgeAlpha',0,'HandleVisibility','off')
        hold on
        plot(timevect,mu,'LineWidth',2,'Color',co(n,:))
    end
    xlim([-100 1000])
    ylim([-.05 .35])
    legend(['Noise ceiling' modnames],'Box','off')
    set(gca,'FontSize',18)
    title(tn)
    ylabel('Spearman correlation')
    xlabel('Time (ms)')

    %% plot bayes factors

    for t=1:length(mods)
        nb=nb+1;
        a=subplot(6,2,6+(t-1)*2+m);hold on
        a.FontSize=20;
        s = stats.(mods{t}).corrs;
        plot(timevect,1+0*timevect,'k-');
        co3 = [.5 .5 .5;1 1 1;co(nb,:)];
        idx = [s.bf<1/10,1/10<s.bf & s.bf<10,s.bf>10]';
        for i=1:3
            x = timevect(idx(i,:));
            y = s.bf(idx(i,:));
            if ~isempty(x)
                stem(x,y,'Marker','o','Color',.6*[1 1 1],'BaseValue',1,'MarkerSize',5,'MarkerFaceColor',co3(i,:),'Clipping','off');
                plot(x,y,'o','Color',.6*[1 1 1],'MarkerSize',5,'MarkerFaceColor',co3(i,:),'Clipping','off');
            end
        end
        a.YScale='log';
        ylim([10.^-5 10.^10])
        a.YTick = 10.^([-5 0 5 10]);
        xlim(minmax(timevect))
        ylabel('BF')
        if t==length(mods)
            xlabel('Time (ms)')
        end
        text(130,0.005,modnames{t},'Fontsize',20,'Color',co(nb,:))
    end
end
annotation('textbox','Units','Normalized','Position', [.06 .92 .05 .05],...
    'LineStyle','none','String','A',...
    'FontSize',30,'VerticalAlignment','middle','HorizontalAlignment','left');
annotation('textbox','Units','Normalized','Position', [.5 .92 .05 .05],...
    'LineStyle','none','String','B',...
    'FontSize',30,'VerticalAlignment','middle','HorizontalAlignment','left');


%% save

fn = '../figures/Fig3_neural-behaviour_rsa';
print(gcf,'-dpng','-r300',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
