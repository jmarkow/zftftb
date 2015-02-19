function [HITS_LOCS,HITS_FEATURES,HITS_FILE_LIST]=ftftb_template_match(TEMPLATE,DIR,varargin)

% do the template matching here...

%disp('Comparing the target sounds to the template...');


if nargin<2 | isempty(DIR)
	DIR=pwd;
end

nparam=length(varargin);
audio_load=[]; % anonymous function for reading MATLAB files
file_filt='*.wav';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION  %%%%%%%%%%%%%%

nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'audio_load'
			audio_load=varargin{i+1};
		case 'file_filt'
			file_filt=varargin{i+1};
	end
end

template_length=size(TEMPLATE{1},2)-1;

listing=dir(fullfile(DIR,file_filt));
listing={listing(:).name};

% TODO: modify load function to allow parfor
% TODO: leverage pdist2, but would require extensive reshaping (overhead may not be worth avoiding for loop)

for i=1:length(listing)

	HITS_LOCS{i}=[];
	HITS_FEATURES{i}=[];
	HITS_FILE_LIST{i}=[];

	score_temp={};
	temp_mat=[];

	% load the features of the sound data

	[pathname,filename,ext]=fileparts(listing{i});
	target_file=fullfile(pathname,'syllable_data',[ filename '_score.mat']);	

	if ~exist(target_file,'file')
		continue;
	end
    
	load(target_file,'features');
	[~,target_length]=size(features{1});

	disp([ listing{i} ])

	for j=1:length(features)

		template=TEMPLATE{j};
		targ=features{j};
		score_temp{j}=zeros(1,target_length-template_length);

		for k=1:target_length-template_length
			score_temp{j}(k)=[sum(sum(abs(targ(:,k:k+template_length)-template)))];
		end

		score_temp{j}=score_temp{j}-mean(score_temp{j});
		score_temp{j}=score_temp{j}/std(score_temp{j});
		score_temp{j}(score_temp{j}>0)=0;
		score_temp{j}=abs(score_temp{j});

	end

	attributes=length(score_temp);
	product_score=score_temp{1};
	curvature=gradient(gradient(product_score));

	% combine scores in various ways
	
	for j=2:attributes, product_score=product_score.*score_temp{j}; end

	% need 3 samples to compute peaks

	if length(product_score)<3
		continue;
	end
	
	warning('off','signal:findpeaks:largeMinPeakHeight');
	[pks,locs]=findpeaks(product_score,'MINPEAKHEIGHT',.005);
	warning('on','signal:findpeaks:largeMinPeakHeight');
	
	if isempty(locs)
		continue; 
	end

	temp_mat=zeros(length(locs),attributes+2);

	for j=1:attributes, temp_mat(:,j)=log(score_temp{j}(locs)); end
	temp_mat(:,attributes+1)=log(product_score(locs));
	temp_mat(:,attributes+2)=log(abs(curvature(locs)));
	
	HITS_LOCS{i}=locs;
	HITS_FEATURES{i}=temp_mat;

end

HITS_FILE_LIST=listing;

