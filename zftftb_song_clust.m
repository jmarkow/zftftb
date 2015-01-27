function zftftb_song_clust(DIR,varargin)
%extracts and aligns renditions of a template
%
%	zftftb_song_clust(pwd)

%	DIR
%	directory that contains the extracted files (default: pwd)
%
%	the following may be specified as parameter/value pairs:
%
%
%		disp_band(1)
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
custom_load='';
file_filt='*.wav';

% TODO: add option to make spectrograms and wavs of all extractions

export_spectrogram=0;
export_wav=0;

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
		case 'song_band'
			song_band=varargin{i+1};
		case 'export_spectrogram'
			export_spectrogram=varargin{i+1};
		case 'export_wav'
			export_wav=varargin{i+1};
		case 'custom_load'
			custom_load=varargin{i+1};
		case 'file_filt'
			file_filt=varargin{i+1};
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DIRECTORY CHECK %%%%%%%%%%%%%%%%%%%%


if nargin<1 | isempty(DIR)
	DIR=pwd;
end

proc_dir=zftftb_directory_check(DIR);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEMPLATE CHECK %%%%%%%%%%%%%%%%%%%%%

% check for previously extracted templates

if ~exist(fullfile(proc_dir,'template_data.mat'),'file')

	[template.data,template.fs]=zftftb_select_template(fullfile(DIR),custom_load);

	% compute the features of the template

	disp('Computing the spectral features of the template');
	[template.features template.feature_parameters]=zftftb_song_score(template.data,template.fs,...
		'len',len,'overlap',overlap,'filter_scale',filter_scale,'downsampling',downsampling,'song_band',song_band);
	save(fullfile(proc_dir,'template_data.mat'),'template','padding');

	template_fig=figure('Visible','off');
	[template_image,f,t]=zftftb_pretty_sonogram(template.data,template.fs,'len',35,'overlap',34.9,'filtering',300,'zeropad',0);

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
		'song_band',song_band,'file_filt',file_filt,'custom_load',custom_load);

	disp('Comparing sound files to the template (this may take a minute)...');
	[hits.locs,hits.features,hits.file_list]=zftftb_template_match(template.features,DIR);

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

total_peaks=sum(cellfun(@length,hits.locs));
non_empty=find(cellfun(@length,hits.locs)>0);
nfeatures=size(hits.features{non_empty(1)},2);

feature_matrix=zeros(total_peaks,nfeatures);
file_id=zeros(total_peaks,1);
peak_order=zeros(total_peaks,1);

counter=1;

for i=1:length(hits.features)
	
	if isempty(hits.features)
		continue;
	end

	for j=1:size(hits.features{i},1)
		feature_matrix(counter,:)=hits.features{i}(j,:);
		file_id(counter)=i;
		peak_order(counter)=j;
		counter=counter+1;
	end
end

if ~skip
	% concatenate features, pass to cluster cut	
	
	[~,labels,selection]=markolab_clust_cut(feature_matrix,property_names);

	% now each row of feature matrix correspond to file id, which corresponds to file list

	save(fullfile(proc_dir,'cluster_results.mat'),'labels','selection');	
else
	load(fullfile(proc_dir,'cluster_results.mat'),'labels','selection');
end

if isempty(padding)
	padding=zeros(1,2);
else
	padding=round(padding.*template.fs);
end

len=round((len/1e3)*template.fs);
overlap=round((overlap/1e3)*template.fs);
stepsize=len-overlap;

select_idx=(labels==selection);

for i=1:length(hits.locs)

	% get the indices for this file

	tmp=select_idx(file_id==i);
	tmp2=peak_order(file_id==i);

	% ensure ordering is correct

	tmp=tmp(tmp2);

	% delete peaks that were not selected

	hits.locs{i}(tmp==0)=[];

end	

for i=1:length(hits.locs)
	
	if isempty(hits.locs{i})
		hits.ext_pts{i}=[];
		continue;
	end

	hits.ext_pts{i}(:,1)=round(((hits.locs{i}-1)*stepsize*downsampling)-padding(1));
	hits.ext_pts{i}(:,2)=hits.ext_pts{i}(:,1)+act_templatesize+padding(2)*2;
end


%% train an SVM to use for classifying new sounds, easily swap in other classifiers

if train_classifier

	disp('Training classifier on your selection...');

	% fix for MATLAB 2010a complaining about too many iterations...enforce that method=smo
	% switched to quadratic kernel function 5/28/13, linear was found to be insufficient in edge-cases

	cluster_choice=selection;

	% quadratic boundaries work the best in this situation

	classobject=svmtrain(feature_matrix,labels,'method','smo','kernel_function','quadratic');
	save(fullfile(proc_dir,'classify_data.mat'),'classobject','cluster_choice');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HIT EXTRACTION %%%%%%%%%%%%%%%%%%%%%


skip=0;
response=[];
if exist(fullfile(proc_dir,'extracted_data.mat'),'file')
	disp('Looks like you have extracted the data before..');

	while isempty(response)
		response=input('Would you like to (r)eextract or (s)kip?  ','s');	
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


	if ~skip
		[agg_audio used_filenames]=zftftb_extract_hits(hits.ext_pts,hits.file_list,'export_wav',export_wav,...
			'export_spectrogram',export_spectrogram,'export_dir',proc_dir);
		disp(['Saving data to ' fullfile(proc_dir,'extracted_data.mat')]);
		save(fullfile(proc_dir,'extracted_data.mat'),'agg_audio','used_filenames','-v7.3');
	end


end
