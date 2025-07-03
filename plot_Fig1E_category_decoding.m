% plot category decoding

files = dir('EEG/results/sub-*_decoding_category_acc.mat');
r=cell(length(files),1);
for f = 1:length(files)
    load(sprintf('EEG/results/%s',files(f).name))
    r{f} = res;
end

res_all = cosmo_stack(r);
res_all = cosmo_average_samples(res_all,'split_by',{'subject','targcomb'});

timevect = res_all.a.fdim.values{1};

%% plot
figure(1);clf
hold on
plot(timevect,timevect*0+0.5,'k','LineWidth',0.5,'HandleVisibility','off')

% co = tab10(3);
co = copper(3);

for a = 1:3
    
    dat = cosmo_slice(res_all,res_all.sa.targcomb==a);
    
    mu = mean(dat.samples,1);
    se = std(dat.samples,[],1)./sqrt(size(dat.samples,1));
    
    fill([timevect fliplr(timevect)],[mu+se fliplr(mu-se)],co(a,:),...
        'FaceAlpha',.2,'LineStyle','none','HandleVisibility','off');
    plot(timevect,mu,'LineWidth',2,'Color',co(a,:))
end

legend({'Human face vs Illusory face','Human face vs Non-face object','Illusory face vs Non-face object'},...
    'Box','off')
set(gca,'Fontsize',20)
ylabel('Decoding accuracy')
xlabel('Time (ms)')
xlim([-100 1000])
ylim([0.48 0.7])
% title('Category decoding')
set(gca,'LineWidth',2)


%% save
fn = 'figures/Fig1E_categorydecoding';
saveas(gcf,fn,'png')
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(imcrop(im,[min([j i])-margin range([j i])+2*margin]),[fn '.png'],'png');
