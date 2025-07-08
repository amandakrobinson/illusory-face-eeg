
%% plot stimuli

load('results/stimorder.mat','stims_FPO');
stims = strcat('Stimuli/',stims_FPO(:,1),'_',stims_FPO(:,2),'.jpg'); % filenames in order we want

names = {'Human faces','Illusory faces','Non-face objects'};

%% plot

f=figure(1);clf;
f.Position = [f.Position(1:2) 1900 1100];
f.Resize = 'off';
aw = 70; % image size
left=50;
bufferw=2;
bufferh=2;
top = f.Position(4)-80;

coords = [1 101 201];

x=0;xy=[];
for cats = 1:12 % rows 
    for i = 1:25 % columns
        x=x+1;
        if ismember(x,[101 201])
            top = top - 50;
        end
        imname = stims{x};
        I = imread(imname);
        imbox = [left+(i-1)*(aw+bufferw) top-cats*(aw+bufferh) aw aw];
        if ismember(x,coords)
            xy(end+1,:) = imbox(1:2); % mark position for later bounding box
        end
        a = axes('Units','pixels','Position',imbox,'Visible','off');
        a.XLim = [.5 250+.5];
        a.YLim = a.XLim;

        h = imshow(I);
    end
end

%% save
fn = 'figures/Fig_stimuli';
saveas(gcf,fn,'png')
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(imcrop(im,[min([j i])-margin range([j i])+2*margin]),[fn '.png'],'png');
