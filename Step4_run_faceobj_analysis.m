
%% analyse face/object discrimination experiment (adrian)
% factors:
% presentation time - short/long
% image type - face/pareidolia/object (300 images)

% load image order
load('results/stimorder.mat','stims_FPO');
ims = stims_FPO;
stims = strcat(stims_FPO(:,1),'_',stims_FPO(:,2),'.jpg'); % stimnames in log file in correct order

%% set up files, factors etc
dat = dir('FaceObjCategorisation/data/*.csv');
names = {dat(:).name};
idx = contains(names,'trialLoop1')|contains(names,'._');
names = names(~idx);

categs = {'face' 'pareidolia' 'object'};
durations = [2 6]; % number of frames: 6 - 100ms, 2 = 33ms

%% read and curate data

acc = NaN(length(names),1);
faceresp = NaN(length(categs),length(durations),length(names));
rt = NaN(length(categs),length(durations),length(names));
faceresp_image = NaN(length(stims_FPO),length(durations),length(names));
rt_image = NaN(length(stims_FPO),length(durations),length(names));

x=0;
for s = 1:length(names)
    dat = readtable(sprintf('FaceObjCategorisation/data/%s',names{s}));
    if height(dat)<66
        continue
    end
    x=x+1;
    % subset table for real trials
    dat = dat(contains(dat.stim_images,'stimuli'),:);

    % make extra columns that are needed
    dat.trialnum = (1:height(dat))';
    dat.stimduration = dat.Stimuli_stopped-dat.Stimuli_started;
    dat.RT = dat.Trials_stopped-dat.Stimuli_started; %dat.key_resp_rt+dat.stimduration;

    % get factors from dataset
    % durations = unique(dat.duration); % 6 - 100ms, 2 = 33ms
    categories = cellfun(@(x) strsplit(x, {'/' '_'}), dat.stim_images, 'UniformOutput', false);
    categories = vertcat(categories{:}); % To remove nesting of cell array newA
    dat.imcategory = categories(:,3);
    images = unique(dat.stim_images); % in no particular order

    % get face response key
    keys = unique(dat.key_resp_keys);
    idx = contains(dat.imcategory,'face');
    facekey = unique(dat.CorrectAns(idx));

    % fix mapping for participants that flipped responses
    acc(x) = mean(dat.key_resp_corr); % response "accuracy"
    if acc(x)<.5 % very poor accuracy = flipped response keys
        facekey = keys(~contains(keys,facekey));
    end

    %% now collate data

    for d = 1:length(durations)
        % calculate response proportions and RTs per image category
        for c = 1:length(categs)

            % get rows of data frame that have that duration and that image category
            idx = find(contains(dat.imcategory,categs{c})&dat.duration==durations(d));

            % count proportion of face responses in those rows
            faceresp(c,d,x) = sum(contains(dat.key_resp_keys(idx),facekey{:}))/length(idx);

            % median RTs for those rows
            rt(c,d,x) = median(dat.RT(idx));

        end

        % calculate response proportion and RTs per image (in order!)
        for i = 1:length(ims)
            % get rows of data frame that have that duration and that image
            idx = find(contains(dat.stim_images,stims{i})&dat.duration==durations(d));

            % count proportion of face responses in those rows
            faceresp_image(i,d,x) = sum(contains(dat.key_resp_keys(idx),facekey{:}))/length(idx);

            % median RTs for those rows
            imrt = dat.RT(idx);
            rt_image(i,d,x) = median(imrt(imrt>.2&imrt<2));
        end
    end
end

%% collate results into results structure

res = struct();
res.categories = categs;
res.images = ims;
res.participants = names;
res.faceresp = faceresp;
res.rt = rt;
res.faceresp_image = faceresp_image;
res.rt_image = rt_image;
res.accuracy = acc;
res.durations = durations;

save('results/faceobjResults.mat','res')