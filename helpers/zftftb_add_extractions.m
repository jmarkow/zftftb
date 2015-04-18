function EXT_PTS=zftftb_add_extractions(HITS,LABELS,SELECTION,FILE_ID,PEAK_ORDER,FS,TEMPLATE_SIZE,varargin)
%
%
%
%


nparams=length(varargin);

padding=[];
len=34;
overlap=33;
downsampling=5;

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
		case 'downsampling'
			downsampling=varargin{i+1};
	end
end

if isempty(padding)
	padding=zeros(1,2);
else
	padding=round(padding.*FS);
end

nlocs=length(HITS.locs);

if length(len)==1
	len=repmat(len,[1 nlocs]);
end

if length(overlap)==1
	overlap=repmat(overlap,[1 nlocs]);
end

if length(downsampling)==1
	downsampling=repmat(downsampling,[1 nlocs]);
end

len=round((len/1e3)*FS);
overlap=round((overlap/1e3)*FS);
stepsize=len-overlap;

select_idx=(LABELS==SELECTION);

for i=1:length(HITS.locs)

	% get the indices for this file

	tmp=select_idx(FILE_ID==i);
	tmp2=PEAK_ORDER(FILE_ID==i);

	% ensure ordering is correct

	tmp=tmp(tmp2);

	% delete peaks that were not selected

	HITS.locs{i}(tmp==0)=[];

end	

for i=1:length(HITS.locs)

	if isempty(HITS.locs{i})
		EXT_PTS{i}=[];
		continue;
	end

	EXT_PTS{i}(:,1)=round(((HITS.locs{i}-1)*stepsize(i)*downsampling(i))-padding(1));
	EXT_PTS{i}(:,2)=EXT_PTS{i}(:,1)+TEMPLATE_SIZE+sum(padding);

end

