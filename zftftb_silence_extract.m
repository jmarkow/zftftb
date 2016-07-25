function zftftb_song_clust(DIR,varargin)
%extracts and aligns renditions of a template
%
%	zftftb_song_clust(pwd)

%	DIR
%	directory that contains the extracted files (default: pwd)
%
%	the following may be specified as parameter/value pairs:
%
%		colors
%		colormap for template spectrogram (default: hot)
%
%		padding
%		padding to the left/right of extractions (two element vector in s, default: [])
%
%		len
%		spectral feature score spectrogram window (in ms, default: 34)
%
%		overlap
%		spectral feature score spectrogram overlap (in ms, default: 33)
%
%		filter_scale
%		spectral feature score smoothing window size, must match ephys_pipeline.cfg (default: 10)
%
%		downsampling
%		spectral feature downsampling factor, must match ephys_pipeline.cfg (default: 5)
%
%		song_band
%		frequency band to compute song features over (in Hz, default: [3e3 9e3])
%
%		audio_load
%		anonymous function that returns two outputs [data,fs]=audio_load(FILE), used for loading
%		data from MATLAB files with custom formats
%
%		file_filt
%		ls filter used to find data files (e.g. '*.wav' for all wav files '*.mat' for all mat)
%
%
%See also zftftb_song_score.m, zftftb_pretty_sonogram.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

colors='hot';
disp_band=[1 10e3]; % spectrogram display parameters
subset='';
padding=1;
min_duration=.05;
song_band=[3e3 9e3];
audio_load='';
data_load='';
file_filt='auto'; % if set to auto, will check for the auto file type, first file wins
extract=1;
thresh=2;

% TODO: add option to make spectrograms and wavs of all extractions

export_spectrogram=1;
export_wav=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION  %%%%%%%%%%%%%%

nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'padding'
			padding=varargin{i+1};
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'song_band'
			song_band=varargin{i+1};
		case 'thresh'
			thresh=varargin{i+1};
		case 'export_spectrogram'
			export_spectrogram=varargin{i+1};
		case 'export_wav'
			export_wav=varargin{i+1};
		case 'audio_load'
			audio_load=varargin{i+1};
		case 'data_load'
			data_load=varargin{i+1};
		case 'file_filt'
			file_filt=varargin{i+1};
		case 'norm_amp'
			norm_amp=varargin{i+1};
		case 'extract'
			extract=varargin{i+1};
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DIRECTORY CHECK %%%%%%%%%%%%%%%%%%%%

if nargin<1 | isempty(DIR)
	DIR=pwd;
end

if strcmp(lower(file_filt),'auto')

	listing=dir(DIR);
	ext=[];

	disp('Auto detecting file type');

	for i=1:length(listing)
		if ~listing(i).isdir & listing(i).name(1)~='.'
			[pathname,filename,ext]=fileparts(listing(i).name);
			new_filt=ext;
		end
	end

	if isempty(ext)
		error('Could not detect file type...');
	end

	file_filt=[ '*' ext ];
	disp(['File filter:  ' file_filt ]);

end

proc_dir='silence';
proc_listing=dir(fullfile(DIR,file_filt));

if strcmp(ext,'.wav')
	audio_load=@(x) wavread(x);
end

silence_hits=cell(1,length(proc_listing));
file_list=cell(1,length(proc_listing));

for i=1:length(proc_listing)

	%

	[y,fs]=audio_load(fullfile(DIR,proc_listing(i).name));
	[~,t,song_ratio,song_pow]=zftftb_song_det(y,fs);

	% make sure silent gaps are padding seconds away from any singing

	silence_idx=song_ratio<thresh;
	song_det_fs=1./(t(2)-t(1));

	padding_smps=round(padding*song_det_fs);
	silence_idx=filtfilt(ones(padding_smps,1)/padding_smps,1,double(silence_idx))>=1;

	% collate into a collection of indices

	hits=round(t(markolab_collate_idxs(silence_idx))*fs);
	hits((diff(hits,[],2)/fs)<min_duration,:)=[];
	silence_hits{i}=hits;
	file_list{i}=fullfile(DIR,proc_listing(i).name);

end

% read in audio data, use song detection output to determine silence
% (can either use raw power or power ratio between song/call and noise parts of spectrum)

response=[];
skip=false;

if extract
	if exist(fullfile(proc_dir,'mat'),'dir') | exist(fullfile(proc_dir,'wav'),'dir') | exist(fullfile(proc_dir,'gif'),'dir')

		disp('Looks like you have extracted the silence data before..');

		while isempty(response)
			response=input('Would you like to (r)eextract or (s)kip?  ','s');
			switch (lower(response))
				case 'r'

					if exist(fullfile(proc_dir,'mat'),'dir')
						rmdir(fullfile(proc_dir,'mat'),'s');
					end

					if exist(fullfile(proc_dir,'gif'),'dir')
						rmdir(fullfile(proc_dir,'gif'),'s');
					end

					if exist(fullfile(proc_dir,'wav'),'dir')
						rmdir(fullfile(proc_dir,'wav'),'s');
					end

					skip=false;
				case 's'
					skip=true;
				otherwise
					response=[];
				end
			end
		end

		if ~skip
			robofinch_extract_data(silence_hits,file_list,proc_dir,'audio_load',audio_load,'data_load',data_load,...
				'export_wav',export_wav,'export_spectrogram',export_spectrogram,'export_dir',proc_dir);
		end


	end
end
