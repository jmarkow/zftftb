function [AUDIO USED_FILENAMES]=zftftb_extract_hits(EXT_PTS,FILENAMES)

USED_FILENAMES={};
AUDIO=[];

disp('Preallocating matrices (this may take a minute)...');

counter=0;

for i=1:length(EXT_PTS)

	if length(EXT_PTS{i})<1
		continue;
	end

	y=wavread(FILENAMES{i});
	len=length(y);

	for j=1:size(EXT_PTS{i},1)
		
		% the startpoint needs to be adjusted using the following formula
		% peaklocation*(WINDOWLENGTH-OVERLAP)*SUBSAMPLING-WINDOWLENGTH

		if EXT_PTS{i}(j,1)>0 && EXT_PTS{i}(j,2)<=len
			counter=counter+1;
		end

	end
end

if counter<1
	return;
end


idx=find(cellfun(@length,EXT_PTS)>0);
ext_length=(EXT_PTS{idx(1)}(1,2)-EXT_PTS{idx(1)}(1,1))+1;

disp(['Found ' num2str(counter) ' trials ']);

%%%%

[y,fs]=wavread(FILENAMES{1});

AUDIO.data=zeros(ext_length,counter,'single');
AUDIO.fs=fs;

trial=1;

for i=1:length(EXT_PTS)

	if length(EXT_PTS{i})<1
		continue;
	end

	[y,fs]=wavread(FILENAMES{i});
	len=length(y);

	for j=1:size(EXT_PTS{i},1)

		startpoint=EXT_PTS{i}(j,1);
		endpoint=EXT_PTS{i}(j,2);

		if startpoint>0 && endpoint<=len

			USED_FILENAMES{end+1}=FILENAMES{i};
			AUDIO.data(:,trial)=single(y(startpoint:endpoint));               

			trial=trial+1;

		end
	end
end
