function [AUDIO DATA USED_FILENAMES]=zftftb_extract_hits(EXT_PTS,FILENAMES,varargin)

USED_FILENAMES={};
AUDIO=[];
DATA=[];

export_wav=0;
export_spectrogram=0;
disp_band=[1 9e3];
export_dir=pwd;
colors='hot';
nparams=length(varargin);
data_load='';
audio_load='';

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'export_spectrogram'
			export_spectrogram=varargin{i+1};
		case 'export_wav'
			export_wav=varargin{i+1};
		case 'export_dir'
			export_dir=varargin{i+1};
		case 'disp_band'
			disp_band=varargin{i+1};
		case 'colors'
			colors=varargin{i+1};
		case 'audio_load'
			audio_load=varargin{i+1};
		case 'data_load'
			data_load=varargin{i+1};
	end
end

disp('Preallocating matrices (this may take a minute)...');

counter=0;

for i=1:length(EXT_PTS)

	if length(EXT_PTS{i})<1
		continue;
	end

	[pathname,filename,ext]=fileparts(FILENAMES{i});

	switch lower(ext)

		case '.wav'

			if verLessThan('matlab','8')
				y=wavread(FILENAMES{i});
			else
				y=audioread(FILENAMES{i});
			end

		case '.mat'

			if ~isempty(audio_load)
				y=audio_load(FILENAMES{i});
			else
				error('No custom loading function detected for .mat files.');
			end

	end

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

if export_wav
	if exist(fullfile(export_dir,'wav'),'dir')
		rmdir(fullfile(export_dir,'wav'),'s');
	end
	mkdir(fullfile(export_dir,'wav'));
end

if export_spectrogram
	if exist(fullfile(export_dir,'gif'),'dir')
		rmdir(fullfile(export_dir,'gif'),'s');
	end

	mkdir(fullfile(export_dir,'gif'));
end

idx=find(cellfun(@length,EXT_PTS)>0);
ext_length=(EXT_PTS{idx(1)}(1,2)-EXT_PTS{idx(1)}(1,1))+1;

disp(['Found ' num2str(counter) ' trials ']);

%%%%

[pathname,filename,ext]=fileparts(FILENAMES{1});

switch lower(ext)

	case '.wav'

		if verLessThan('matlab','8')
			[y,fs]=wavread(FILENAMES{1});
		else
			[y,fs]=audioread(FIlENAMES{1});
		end

	case '.mat'

		if ~isempty(audio_load)
			[y,fs]=audio_load(FILENAMES{1});
		else
			error('No custom loading function detected for .mat files.');
		end

end

AUDIO.data=zeros(ext_length,counter,'single');
AUDIO.fs=fs;
AUDIO.bout_count=zeros(1,counter);
AUDIO.motif_count=zeros(1,counter);
AUDIO.motif_total=zeros(1,counter);
AUDIO.filename=cell(1,counter);

if ~isempty(data_load)
	[y2,~,labels,ports]=data_load(FILENAMES{1});
	[nsamples,nchannels]=size(y2);
	DATA.data=zeros(ext_length,counter,nchannels,'single');
	DATA.fs=fs;
	DATA.labels=labels;
	DATA.ports=ports;
	DATA.bout_count=zeros(1,counter);
	DATA.motif_count=zeros(1,counter);
	DATA.motif_total=zeros(1,counter);
	DATA.filename=cell(1,counter);
end


trial=1;
y2=[];

for i=1:length(EXT_PTS)

	if length(EXT_PTS{i})<1
		continue;
	end

	[pathname,filename,ext]=fileparts(FILENAMES{i});

	switch lower(ext)

		case '.wav'

			if verLessThan('matlab','8')
				[y,fs]=wavread(FILENAMES{i});
			else
				[y,fs]=audioread(FILENAMES{i});
			end

		case '.mat'

			if ~isempty(audio_load)
				[y,fs]=audio_load(FILENAMES{i});
			else
				error('No custom loading function detected for .mat files.');
			end

			if ~isempty(data_load)
				y2=data_load(FILENAMES{i});
			else
				y2=[];
			end

	end

	len=length(y);
	filecount=1;
	[pathname,filename,ext]=fileparts(FILENAMES{i});

	% get bout structure for file


	[b,a]=ellip(5,.2,40,[500]/(fs/2),'high');
	tmp=filtfilt(b,a,y);
	tmp=tmp./max(abs(tmp));

	[song_det,song_det_t]=zftftb_song_det(tmp,fs);
	raw_t=[1:len]/fs;

	detection=interp1(song_det_t,double(song_det),raw_t,'nearest');

	bouts=markolab_collate_idxs(detection,round(.1*fs));
	nbouts=size(bouts,1);

	bout_count=ones(1,size(EXT_PTS{i},1))*NaN;

	for j=1:size(EXT_PTS{i},1)

		startpoint=EXT_PTS{i}(j,1);
		endpoint=EXT_PTS{i}(j,2);

		for k=1:nbouts
			if startpoint>=bouts(k,1) & endpoint<=bouts(k,2)
				bout_count(j)=k;
				break;
			end
		end

	end

	motif_count=zeros(size(bout_count));
	motif_total=zeros(size(bout_count));

	for j=1:length(bout_count)

		[val idx]=find(bout_count==bout_count(j));

		if isnan(bout_count(j))
			motif_count(j)=NaN;
			motif_total(j)=NaN;
			continue;
		end

		motif_count(j)=find(idx==j);
		motif_total(j)=sum(bout_count==bout_count(j));

	end

	for j=1:size(EXT_PTS{i},1)

		startpoint=EXT_PTS{i}(j,1);
		endpoint=EXT_PTS{i}(j,2);

		if startpoint>0 && endpoint<=len

			USED_FILENAMES{end+1}=FILENAMES{i};
			AUDIO.data(:,trial)=single(y(startpoint:endpoint));
			AUDIO.bout_count(trial)=bout_count(j);
			AUDIO.motif_total(trial)=motif_total(j);
			AUDIO.motif_count(trial)=motif_count(j);
			AUDIO.filename{trial}=FILENAMES{i};

			if ~isempty(y2)

				for k=1:nchannels
					DATA.data(:,trial,k)=single(y2(startpoint:endpoint,k));
				end

				DATA.bout_count(trial)=bout_count(j);
				DATA.motif_total(trial)=motif_total(j);
				DATA.motif_count(trial)=motif_count(j);
				DATA.filename{trial}=FILENAMES{i};
			end

			export_file=fullfile([filename '_chunk_' num2str(filecount)]);

			if export_wav

				tmp=AUDIO.data(:,trial);

				min_audio=min(tmp);
				max_audio=max(tmp);

				if min_audio + max_audio < 0
					tmp=tmp/(-min_audio);
				else
					tmp=tmp/(max_audio*(1+1e-3));
				end

				if verLessThan('matlab','8')
					wavwrite(tmp,AUDIO.fs,fullfile(export_dir,'wav',[ export_file '.wav' ]));
				else
					audiowrite(fullfile(export_dir,'wav',[export_file '.wav']),tmp,AUDIO.fs);
				end
			end

			if export_spectrogram

				[im,f,t]=zftftb_pretty_sonogram(double(AUDIO.data(:,trial)),AUDIO.fs,'len',16.7,'overlap',14,'zeropad',0,'filtering',500,...
					'clipping',[-3 2],'norm_amp',1);

				startidx=max([find(f<=disp_band(1))]);
				stopidx=min([find(f>=disp_band(2))]);

				im=im(startidx:stopidx,:)*62;
				im=flipdim(im,1);
				[f,t]=size(im);

				imwrite(uint8(im),colormap([ colors '(63)']),fullfile(export_dir,'gif',[ export_file '.gif']),'gif');

			end

			filecount=filecount+1;
			trial=trial+1;
		end
	end

end
