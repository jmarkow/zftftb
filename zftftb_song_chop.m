function zftftb_song_chop(DIR,varargin)
%zftftb_song_chop takes a directory of wav files, and extracts all segments of the wav files
%that contain sound.  Useful in cases where you don't care about using the silent segments.
%
%	zftftb_song_chop(DIR,varargin)
%
%	DIR
%	directory of .wav files to process
%
%	the following may be passed as parameter/value pairs:
%
%		song_len
%		window length for computing power band crossing (in s, default: .005)
%
%		song_overlap
%		window overlap for computing power band crossing (in s, default: 0)
%
%		song_band
%		frequencies that contain relevant sound (in Hz, default: [3e3 7e3])
%
%		song_ratio
%		ratio of power in:out of relevant band (default: 2)
%
%		song_duration
%		smoothing of song_ratio (in s, default: .8)
%
%		song_pow
%		threshold on song power (default: -inf)
%
%		song_thresh
%		threshold on smoothed song_ratio (default: .1)
%	
%		custom_load
%		anonymous functionf or loading MATLAB data (default: '')
%
%		file_filt
%		filter for file selection (default: '*.wav')
%
%		audio_pad
%		data to include to the left/right of extraction points (in s, default: 1)
%
%		colors
%		MATLAB colormap to use for spectrograms (default: 'hot');
%		
%		disp_band
%		frequency band to display for spectrogram export (default: [1 9e3]);
%
%		export_wav
%		enable wav file export (default: 1)
%
%		export_spectrogram
%		enable spectrogram export (default: 1)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION  %%%%%%%%%%%%%%

if nargin<1 | isempty(DIR)
	DIR=pwd;
end

nparam=length(varargin);

song_len=.005;
song_overlap=0;
song_band=[3e3 7e3];
song_duration=.8;
song_ratio=2;
song_pow=-inf;
song_thresh=.1;

custom_load=[]; % anonymous function for reading MATLAB files
file_filt='*.wav';
audio_pad=[ 1 ];
colors='hot';
disp_band=[1 9e3];

export_wav=1;
export_spectrogram=1;


nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'song_len'
			song_len=varargin{i+1};
		case 'song_overlap'
			song_overlap=varargin{i+1};
		case 'song_band'
			song_band=varargin{i+1};
		case 'song_duration'
			song_duration=varargin{i+1};
		case 'song_ratio'
			song_ratio=varargin{i+1};
		case 'song_pow'
			song_pow=varargin{i+1};
		case 'song_thresh'
			song_thresh=varargin{i+1};
		case 'export_spectrogram'
			export_spectrogram=varargin{i+1};
		case 'export_wav'
			export_wav=varargin{i+1};
		case 'custom_load'
			custom_load=varargin{i+1};
		case 'file_filt'
			file_filt=varargin{i+1};
		case 'audio_pad'
			audio_pad=varargin{i+1};
		case 'colors'
			colors=varargin{i+1};
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(fullfile(DIR,'chop_data'),'dir')
	mkdir(fullfile(DIR,'chop_data'));
end

listing=dir(fullfile(DIR,file_filt));
listing={listing(:).name};

if export_wav
	mkdir(fullfile(DIR,'chop_data','wav'));
end

if export_spectrogram
	mkdir(fullfile(DIR,'chop_data','gif'));
end

for i=1:length(listing)

	input_file=listing{i};
	disp([input_file])
	
	[pathname,filename,ext]=fileparts(input_file);
	
	switch lower(ext)
		case '.mat'
			% use custom loading function
			
			if ~isempty(custom_load)
				[audio_data,audio_fs]=custom_load(input_file);
			else
				error('No custom loading function detected for .mat files.');
			end
			
		case '.wav'

			[audio_data,audio_fs]=wavread(input_file);
	end

	disp('Entering song detection...');
	audio_len=length(audio_data);

	[song_bin,song_t]=zftftb_song_det(audio_data,audio_fs,'song_band',song_band,...
		'len',song_len,'overlap',song_overlap,'song_duration',song_duration,...
		'ratio_thresh',song_ratio,'song_thresh',song_thresh,'pow_thresh',song_pow);

	raw_t=[1:audio_len]./audio_fs;

	% interpolate song detection to original space, collate idxs

	detection=interp1(song_t,double(song_bin),raw_t,'nearest'); 
	ext_pts=markolab_collate_idxs(detection,round(audio_pad*audio_fs));

	for j=1:size(ext_pts,1)

		% grab chunk if possible
		
		curr_ext=ext_pts(j,:);
		export_file=[ filename '_chunk_' num2str(j) ];	
		
		if curr_ext(1)>0 & curr_ext(2)<audio_len

			% now we're extracting
			%

			extraction=audio_data(curr_ext(1):curr_ext(2));
			
			if export_wav

				tmp=extraction;

				min_audio=min(tmp);
				max_audio=max(tmp);

				if min_audio + max_audio < 0
					tmp=tmp/(-min_audio);
				else
					tmp=tmp/(max_audio*(1+1e-3));
				end

				wavwrite(tmp,audio_fs,fullfile(DIR,'chop_data','wav',[ export_file '.wav' ]));


			end

			if export_spectrogram

				[im,f,t]=zftftb_pretty_sonogram(extraction,audio_fs,'len',16.7,'overlap',14,'zeropad',0);

				startidx=max([find(f<=disp_band(1))]);
				stopidx=min([find(f>=disp_band(2))]);

				im=im(startidx:stopidx,:)*62;
				im=flipdim(im,1);
				[f,t]=size(im);

				imwrite(uint8(im),colormap([ colors '(63)']),fullfile(DIR,'chop_data','gif',[ export_file '.gif']),'gif');

			end

		end
	end
end
