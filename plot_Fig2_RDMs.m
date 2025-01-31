%% plot Figure 2: RDMS for tasks, category models and MDS plots for the neural data at three different time windows

%% load
load('results/rdms_all.mat','rdms','timevect')

%% set up neural RDMs and MDS starting point
cols = viridis(4);

neuraltimes =[90 150 300]; % time points
adds = [40 60 50];

% neural rdms
for n = 1:3
    idx = timevect>neuraltimes(n)&timevect<(neuraltimes(n)+adds(n));
    rdm = squareform(mean(rdms.neural.RDM(:,idx),2));
    neur(:,n) = squareform(rdm);
    names{n} = sprintf('Neural %d-%d ms',neuraltimes(n),neuraltimes(n)+adds(n));
end

% get starting point MDS
x = mdscale(squareform(neur(:,3)),2,'Start','random','Replicates',20);
x1start = x;

%% plot RDMs for task and category models

f=figure(2);clf;
f.Position = [f.Position(1:2) 1200 1400];
f.Resize = 'off';

% plot ratings
models = fieldnames(rdms);
models = models([4:6 1 3 2]);

for m = 1:length(models)

    a=subplot(4,3,m);
    set(a,'FontSize',12)
    hold on
    rdm = rdms.(models{m}).RDM;
    rdm(eye(size(rdm))==1)=0; % diagonal set to 0 (not nan)
    
    imagesc(rdm);
    axis square
    % axis off
    a.YDir='normal';
    colormap plasma

    xlim([1 300])
    ylim([1 300])
    a.XTick = [50:100:250];

    if ismember(m,1:6)
        a.XTickLabel = {'Human\newlinefaces' 'Illusory\newlinefaces' 'Non-face\newlineobjects'};
    else
        a.XTickLabel = [];
    end

    a.YTick = [50:100:250];
    if ismember(m,[1 4])
        a.YTickLabel = {'Human\newlinefaces' 'Illusory\newlinefaces' 'Non-face\newlineobjects'};
    else
        a.YTickLabel = [];
    end

    if m == 3
        cb1=colorbar('Ticks',[min(rdm(:)) max(rdm(:))],'TickLabels',{'Highly\newlinesimilar' 'Highly\newlinedissimilar'});
        cb1.Position = [cb1.Position(1)+.05 cb1.Position(2:4)];
        cb1.FontSize = 15;
    elseif m == 6
        set(gca,'Colormap',plasma(2))
        cb2=colorbar('Ticks',[.25 .75],'TickLabels',{'Same' 'Different'});
        cb2.Position = [cb2.Position(1)+.05 cb2.Position(2:4)];
        cb2.FontSize = 15;
    end

    t=title(rdms.(models{m}).name);
    t.Position(2) = t.Position(2)+15
    t.FontSize = 18;
    % t.Position(2) = t.Position(2)+.2;


    a.XRuler.Axle.LineStyle = 'none';
    a.YRuler.Axle.LineStyle = 'none';


end



%% plot neural MDS and downsampled RDMs

for c=1:size(neur,2)

    X1 = mdscale(squareform(neur(:,c)),2,'Start',x1start);

    % colour-code different categories and plot MDS
    p=subplot(4,3,6+c);
    p.Position = [p.Position(1) p.Position(2)-.06 p.Position(3:4)];
    hold on
    X=X1;
    % axis equal
    axis square
    axis off
    for i=1:3
        idx = (i-1)*100+1;
        plot(X(idx:(idx+99),1),X(idx:(idx+99),2),'.','Color',cols(i,:),'MarkerSize',15)
        % meancat(:,i,c) = [mean(X(idx:(idx+99),1)),mean(X(idx:(idx+99),2))];
        % secat(:,i,c) = [std(X(idx:(idx+99),1))/sqrt(100),std(X(idx:(idx+99),2))/sqrt(100)];
    end
    p.XLim = [-.4 .4];
    p.YLim = [-.4 .4];
    p.XTick = [];
    p.YTick = [];
    set(gca,'LineWidth',2)
    t=title(sprintf('Neural %d-%d ms',neuraltimes(c),neuraltimes(c)+adds(c)));%rdms.(models{m}).name)
    t.FontSize = 18;
    t.Position(2) = t.Position(2)+.2;

    % downsample
    rdm = squareform(neur(:,c));
    meancat = [];
    for i1=1:3
        for i2=1:3
            idx1 = (i1-1)*100+1;
            idx2 = (i2-1)*100+1;
            dat = rdm(idx1:(idx1+99),idx2:(idx2+99));
            if idx1==idx2
                dat = squareform(dat);
            end
            meancat(i1,i2) = nanmean(dat(:));
        end
    end

    a=axes('Units','normalized','Position',[0.27+(c-1)*.28 0.4 0.06 0.06],'Visible','on');
    imagesc(meancat,[.5 .6])
    colormap(a,plasma)
    axis square
    % axis off
    a.XTickLabel = {'HF' 'IF' 'NFO'};
    a.YTickLabel = {'HF' 'IF' 'NFO'};

    if c == 3
        cb=colorbar;
        cb.Position = [cb2.Position(1) cb2.Position(2)-(cb1.Position(2)-cb2.Position(2))-.04 cb2.Position(3:4)]
        cb.FontSize = 15;

        ylabel(cb,'Mean decoding accuracy','FontSize',16,'Rotation',270)

    end
    t=title('')
    a.YDir='normal';
    a.XRuler.Axle.LineStyle = 'none';
    a.YRuler.Axle.LineStyle = 'none';


end

%% save RDM figures
fn = 'figures/Figure2_RDMs';
print(gcf,'-dpng','-r300',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
