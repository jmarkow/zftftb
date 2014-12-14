function zftftb_batch_features(DIR,varargin)
%
%

if nargin<1 | isempty(DIR)
	DIR=pwd;
end

nparam=length(varargin);

len=34;
overlap=33;
filter_scale=10;
downsampling=5;
song_band=[3e3 9e3];
custom_load=[]; % anonymous function for reading MATLAB files
file_filt='*.wav';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION  %%%%%%%%%%%%%%

nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'filter_scale'
			filter_scale=varargin{i+1};
		case 'downsampling'
			downsampling=varargin{i+1};
		case 'song_band'
			song_band=varargin{i+1};
		case 'custom_load'
			custom_load=varargin{i+1};
		case 'file_filt'
			file_filt=varargin{i+1};
	end
end


par_save = @(FILE,features,parameters) save(FILE,'features','parameters');

if ~exist(fullfile(DIR,'syllable_data'),'dir')
	mkdir(fullfile(DIR,'syllable_data'));
end

listing=dir(fullfile(DIR,file_filt));
listing={listing(:).name};

parfor i=1:length(listing)

	audio_data=[];
	audio_fs=[];

	input_file=listing{i};
	disp([input_file])

	[pathname,filename,ext]=fileparts(input_file);
	output_file=fullfile(DIR,'syllable_data',[ filename '_score.mat']);

	if exist(output_file,'file'), continue; end

	disp(['Computing features for ' input_file]);

	% simply read in the file and score it
	% getfield hack to get around parfor errors

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
	
	if length(audio_data)<len
		warning('Sound extraction too short in %s, skipping...',input_file);
		continue;
	end

	[sound_features,parameters]=zftftb_song_score(audio_data,audio_fs,...
		'len',len,'overlap',overlap,'filter_scale',filter_scale,'downsampling',downsampling,'song_band',song_band);

	% save for posterity's sake

	par_save(output_file,sound_features,parameters);

end