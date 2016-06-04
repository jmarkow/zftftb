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
padding=[]; % padding that will be saved with the template, in seconds (relevant for the pipeline only)
   	    % two elements vector, both specify in seconds how much time before and after to extract
	    % e.g. [.2 .2] will extract 200 msec before and after the extraction point when clustering
	    % sounds through the pipeline

len=34;
overlap=33;
filter_scale=10;
downsampling=5;
train_classifier=0;
song_band=[3e3 9e3];
spec_sigma=1.5;
norm_amp=0;
audio_load='';
data_load='';
file_filt='auto'; % if set to auto, will check for the auto file type, first file wins
extract=1;
clust_lim=1e4; % number of points to display for cluster cut

% TODO: add option to make spectrograms and wavs of all extractions

export_spectrogram=1;
export_wav=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CLASSIFICATION FEATURES NAME %%%%%%%

property_names={'cos','derivx', 'derivy', 'amp','product','curvature'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION  %%%%%%%%%%%%%%

nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'padding'
			padding=varargin{i+1};
		case 'train_classifier'
			train_classifier=varargin{i+1};
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'filter_scale'
			filter_scale=varargin{i+1};
		case 'downsampling'
			downsampling=varargin{i+1};
		case 'spec_sigma'
			spec_sigma=varargin{i+1};
		case 'song_band'
			song_band=varargin{i+1};
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
		case 'clust_lim'
			clust_lim=varargin{i+1};
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

proc_dir=zftftb_directory_check(DIR);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEMPLATE CHECK %%%%%%%%%%%%%%%%%%%%%

% check for previously extracted templates

if ~exist(fullfile(proc_dir,'template_data.mat'),'file')

	[template.data,template.fs]=zftftb_select_template(fullfile(DIR),audio_load);

	% compute the features of the template

	disp('Computing the spectral features of the template');
	[template.features template.feature_parameters]=zftftb_song_score(template.data,template.fs,...
		'len',len,'overlap',overlap,'filter_scale',filter_scale,'downsampling',downsampling,...
		'song_band',song_band,'spec_sigma',spec_sigma,'norm_amp',norm_amp);
	save(fullfile(proc_dir,'template_data.mat'),'template','padding');

	template_fig=figure('Visible','off');
	[template_image,f,t]=zftftb_pretty_sonogram(template.data,template.fs,'len',35,'overlap',34.9,'filtering',300,'zeropad',0,'norm_amp',1);

	startidx=max([find(f<=disp_band(1));1]);

	if isempty(startidx)
		startidx=1;
	end

	stopidx=min([find(f>=disp_band(2));length(f)]);

	if isempty(stopidx)
		stopidx=length(f);
	end

	imagesc(t,f(startidx:stopidx),template_image(startidx:stopidx,:));
	set(gca,'ydir','normal');

	xlabel('Time (in s)');
	ylabel('Fs');
	colormap(colors);
	markolab_multi_fig_save(template_fig,proc_dir,'template','png');

	close([template_fig]);

else

	disp('Loading stored template...');
	load(fullfile(proc_dir,'template_data.mat'),'template');
	save(fullfile(proc_dir,'template_data.mat'),'padding','-append'); % append in case we change padding

end

act_templatesize=length(template.data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GET DIFFERENCE SCORES %%%%%%%%%%%%%%

% have we computed the difference between the template and the sound data?

skip=0;
response=[];
if exist(fullfile(proc_dir,'cluster_data.mat'),'file')
	disp('Looks like you have computed the scores before...');

	while isempty(response)
		response=input('Would you like to (r)ecompute or (s)kip to clustering?  ','s');
		switch (lower(response))
			case 'r'
				skip=0;
			case 's'
				skip=1;
			otherwise
				response=[];
		end
	end
end

% if we haven't computed the scores, do it!

if ~skip

	% collect all of the relevant .mat files

	disp('Computing features for all sounds...');
	zftftb_batch_features(DIR,'len',len,'overlap',overlap,...
		'filter_scale',filter_scale,'downsampling',downsampling,...
		'song_band',song_band,'file_filt',file_filt,'audio_load',...
		audio_load,'spec_sigma',spec_sigma,'norm_amp',norm_amp);

	disp('Comparing sound files to the template (this may take a minute)...');
	[hits.locs,hits.features,hits.file_list]=zftftb_template_match(template.features,DIR,'file_filt',file_filt);

	% convert hit locations to points in file


	save(fullfile(proc_dir,'cluster_data.mat'),'hits');

else
	load(fullfile(proc_dir,'cluster_data.mat'),'hits');
end

% do we need to cluster again?

skip=0;
response=[];
if exist(fullfile(proc_dir,'cluster_results.mat'),'file')
	disp('Looks like you have clustered the data before..');

	while isempty(response)
		response=input('Would you like to (r)ecluster or (s)kip?  ','s');
		switch (lower(response))
			case 'r'
				skip=0;
			case 's'
				skip=1;
			otherwise
				response=[];
		end
	end
end

% collect features into matrix, make sure we can map it back to cell

[feature_matrix,file_id,peak_order]=zftftb_hits_to_mat(hits);

if ~skip
	% concatenate features, pass to cluster cut

	[~,labels,selection,features_used]=markolab_clust_cut(feature_matrix,property_names,[],clust_lim);

	% now each row of feature matrix correspond to file id, which corresponds to file list


	save(fullfile(proc_dir,'cluster_results.mat'),'labels','selection','features_used');
else
	load(fullfile(proc_dir,'cluster_results.mat'),'labels','selection','features_used');
end

hits.ext_pts=zftftb_add_extractions(hits,labels,selection,file_id,peak_order,template.fs,act_templatesize,...
	'len',len,'overlap',overlap,'padding',padding);

save(fullfile(proc_dir,'cluster_results.mat'),'hits','-append');

%% train an SVM to use for classifying new sounds, easily swap in other classifiers

if train_classifier

	disp('Training classifier on your selection...');

	% fix for MATLAB 2010a complaining about too many iterations...enforce that method=smo
	% switched to quadratic kernel function 5/28/13, linear was found to be insufficient in edge-cases

	cluster_choice=selection;

	% quadratic boundaries work the best in this situation

	% two classes, selection, non-selection

	labels(labels~=cluster_choice)=NaN;
	labels(labels==cluster_choice)=2; % hits are class 2
	labels(isnan(labels))=1; % non-hits are class 1
	cluster_choice=2; % what are hits?

	svm_object=svmtrain(feature_matrix(:,features_used),labels,'method','smo','kernel_function','quadratic');

	% specify a classifier function (this will make using other clustering methods simple in the future)

	class_fun=@(FEATURES) svmclassify(svm_object,FEATURES);

	save(fullfile(proc_dir,'classify_data.mat'),'svm_object','class_fun','cluster_choice','features_used');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HIT EXTRACTION %%%%%%%%%%%%%%%%%%%%%

skip=0;
response=[];

if extract
	if exist(fullfile(proc_dir,'mat'),'dir') | exist(fullfile(proc_dir,'wav'),'dir') | exist(fullfile(proc_dir,'gif'),'dir')

		disp('Looks like you have extracted the data before..');

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

					skip=0;
				case 's'
					skip=1;
				otherwise
					response=[];
				end
			end
		end

		if ~skip
			robofinch_extract_data(hits.ext_pts,hits.file_list,proc_dir,'audio_load',audio_load,'data_load',data_load,...
				'export_wav',export_wav,'export_spectrogram',export_spectrogram,'export_dir',proc_dir);
		end


	end
end
