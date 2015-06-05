function [FEATURE_MATRIX,FILE_ID,PEAK_ORDER]=zftftb_hits_to_mat(HITS)
%
%
%


FEATURE_MATRIX=[];
FILE_ID=[];
PEAK_ORDER=[];

if isempty(HITS.locs)
	return;
end

total_peaks=sum(cellfun(@length,HITS.locs));
non_empty=find(cellfun(@length,HITS.locs)>0);

if length(non_empty)==0
	return;
end

nfeatures=size(HITS.features{non_empty(1)},2);

FEATURE_MATRIX=zeros(total_peaks,nfeatures);
FILE_ID=zeros(total_peaks,1);
PEAK_ORDER=zeros(total_peaks,1);

counter=1;

for i=1:length(HITS.features)
	
	if isempty(HITS.features)
		continue;
	end

	for j=1:size(HITS.features{i},1)
		FEATURE_MATRIX(counter,:)=HITS.features{i}(j,:);
		FILE_ID(counter)=i;
		PEAK_ORDER(counter)=j;
		counter=counter+1;
	end
end

