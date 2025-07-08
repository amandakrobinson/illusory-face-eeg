%% analyse ratings
% analyse face-like ratings for 300 stimuli
% reorder to f-p-o for analyses

% load reordering matrix
load('results/stimorder.mat','stimnames_FPO');

%% read data from face-likeness ratings

fn = dir('results/qualtrics-face-likeness-data.xlsx');
rawdata = readtable([fn.folder '/' fn.name]);

gender = rawdata(:,19);
age = rawdata(:,20);

fprintf('There are %d females from %d participants\n',sum(contains(gender.Sex,'Female')),height(gender));
fprintf('Median age is %d, range %d to %d\n',median(age.Age),min(age.Age),max(age.Age));


% get columns with ratings data
rawdata = rawdata(:,21:(size(rawdata,2)-1));


%% now get stimulus names from rawdata in same format as stimnames_reordered
% get stimuli names from column names
names = rawdata.Properties.VariableNames;

% rename question labels to be consistent with stimulus names
namecat = cellfun(@(x) x(1),names, 'UniformOutput', false);
namecat(contains(namecat,'h')) = {'face'};
namecat(contains(namecat,'o')) = {'object'};
namecat(contains(namecat,'p')) = {'pareidolia'};
namenum = cellfun(@(x) x((length(x)-2):length(x)),names, 'UniformOutput', false);

for s = 1:length(namecat)
    rating_stimorder{s,1} = [namecat{s} namenum{s}];
end

%% collate data
ratingsdat = struct();
ratingsdat.stim = cell(length(stimnames_FPO),1);
stimidx = zeros(length(stimnames_FPO),1);
for s = 1:length(stimnames_FPO)
    
    stimidx(s) = find(ismember(rating_stimorder,stimnames_FPO(s)));

    dat = rawdata(:,stimidx(s));
    ratingsdat.stim(s) = dat.Properties.VariableNames;
    dat = table2array(dat);
    if ~contains(class(dat),'double')
        dat = cellfun(@str2num, dat);
    end

    ratingsdat.modal(s) = mode(dat,1); % modal score per stim
    ratingsdat.alldat(:,s) = dat; % all dat
    ratingsdat.mean(s) = mean(dat,1); % mean score per stim

end

save('results/facelike_ratings.mat','ratingsdat')
