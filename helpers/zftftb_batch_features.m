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
spec_sigma=1.5;
song_band=[3e3 9e3];
audio_load=[]; % anonymous function for reading MATLAB files
file_filt='*.wav';
store_dir='syllable_data';
file_suffix='_score';
norm_amp=1;

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
		case 'audio_load'
			audio_load=varargin{i+1};
		case 'file_filt'
			file_filt=varargin{i+1};
		case 'store_dir'
			store_dir=varargin{i+1};
		case 'file_suffix'
			file_suffix=varargin{i+1};
		case 'spec_sigma'
			spec_sigma=varargin{i+1};
		case 'norm_amp'
			norm_amp=varargin{i+1};
	end
end


par_save = @(FILE,features,parameters) save(FILE,'features','parameters');

if ~iscell(DIR)
	if ~exist(fullfile(DIR,'syllable_data'),'dir')
		mkdir(fullfile(DIR,'syllable_data'));
	end

	listing=dir(fullfile(DIR,file_filt));
	listing={listing(:).name};
else

	listing=DIR;
	for i=1:length(listing)
		[pathname,filename,ext]=fileparts(listing{i});
		if ~exist(fullfile(pathname,store_dir),'dir')
			mkdir(fullfile(pathname,store_dir));
		end
	end

end

nhits=length(listing);

if length(len)==1, len=repmat(len,[1 nhits]); end
if length(overlap)==1, overlap=repmat(overlap,[1 nhits]); end
if length(filter_scale)==1, filter_scale=repmat(filter_scale,[1 nhits]); end
if length(downsampling)==1, downsampling=repmat(downsampling,[1 nhits]); end
if size(song_band,1)==1, song_band=repmat(song_band,[nhits 1]); end
if length(spec_sigma)==1, spec_sigma=repmat(spec_sigma,[1 nhits]); end
if length(norm_amp)==1, norm_amp=repmat(norm_amp,[1 nhits]); end

if length(audio_load)==1 
	audio_load=repmat(audio_load,[1 nhits]);
end

parfor i=1:nhits

	audio_data=[];
	audio_fs=[];

	input_file=listing{i};
	disp([input_file])

	[pathname,filename,ext]=fileparts(input_file);
	output_file=fullfile(pathname,store_dir,[ filename file_suffix '.mat']);

	if exist(output_file,'file'), continue; end
	disp(['Computing features for ' input_file]);

	% simply read in the file and score it
	% getfield hack to get around parfor errors

	switch lower(ext)
		case '.mat'
			% use custom loading function
			
			if ~isempty(audio_load)

				[audio_data,audio_fs]=audio_load{i}(input_file);
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
		'len',len(i),'overlap',overlap(i),'filter_scale',filter_scale(i),...
		'downsampling',downsampling(i),'song_band',song_band(i,:),'spec_sigma',spec_sigma(i),...
		'norm_amp',norm_amp(i));

	% save for posterity's sake

	par_save(output_file,sound_features,parameters);


end
