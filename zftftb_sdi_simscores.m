function SCORES=zftftb_sdi_simscores(CONTOUR_GROUP1,CONTOUR_GROUP2,F,T,varargin)
%zftftb_sdi_simscore computes similarity scores between two groups of contours, this
%method is incredibly sensitive, it is recommended to use a bootstrap to determine
%the *expected* difference in similarity scores for sounds from the same *group*
%
%	[SCORES]=zftftb_sdi_simscores(CONTOUR_GROUP1,CONTOUR_GROUP2,F,T,varargin)
%
%	CONTOUR_GROUP1
%	3D matrix of contours returned by zftftb_sdi (either the re or im field)
%
%	CONTOUR_GROUP2
%	3D matrix of contours returned by zftftb_sdi (either the re or im field)
%
%	F
%	frequency vector returned by zftftb_sdi
%
%	T
%	time vector returned by zftftb_sdi
%
%	the following may be specified as parameter/value pairs:
%
%		time_range
%		time in seconds to compute the scores over (two element vector, in s,
%		e.g. [.2 .8] will compute scores between 200 and 800 ms)
%
%		freq_band
%		frequency in Hz to compute score over (two element vector, e.g. [2e3 8e3]
%		will compute scores between 2 and 8 kHz)
%
%	the program returns the following outputs
%
%	SCORES
%	M X N cell array of similarity scores, where M is the group of contours and N is the SDI
%
%	example:
%
%	Start by computing the contours for a set of microphone signals with a sampling rate of 24 kHz
%
%	[sdi f t contours]=zftftb_sdi(mic_signals,24e3);
%
%	Now you want to compare the first 100 trials with the last 100, and compare the signals
%	between 200 and 800 msecs and 2000 and 9000 Hz using the imaginary contours
%
%	scores=zftftb_sdi_simscores(contours.im(:,:,1:100),contours.im(:,:,end-100:end),f,t,'time_range',[.2 .8],...
%				    'freq_range',[2e3 9e3]);
%
%	The similarity scores between group 1 contours and SDI 1 (i.e. self-similarity) is scores{1,1}, then
%	the cross-similarity between group 2 contours and SDI 1 is scores{2,1}
%
%	dprime=(mean(scores{1,1})-mean(scores{2,1}))./std([scores{1,1};scores{2,1}])
%
%	This returns a dprime-like measure to compare the difference between the first and second group. Given the sensitivity
%	of the measure (0-.4 tends to indicate no effect, >.6 a moderate effect, >1 a strong effect).  It's advised to run a
%	bootstrap to determine a rigorous cutoff.


nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

time_range=[T(1) T(end)];
freq_band=[3e3 9e3];

for i=1:2:nparams
	switch lower(varargin{i})
		case 'time_range'
			time_range=varargin{i+1};
		case 'freq_band'
			freq_band=varargin{i+1};
	end
end

mint=max(find(T<=time_range(1)));
maxt=min(find(T>=time_range(2)));
minf=max(find(F<=freq_band(1)));
maxf=min(find(F>=freq_band(2)));

if isempty(mint), mint=1; end
if isempty(maxt), maxt=length(T); end
if isempty(minf), minf=1; end
if isempty(maxf), maxf=length(F); end

[rows1,columns1,trials1]=size(CONTOUR_GROUP1);
[rows2,columns2,trials2]=size(CONTOUR_GROUP2);

if (rows1 ~= rows2) | (columns1 ~= columns2)
	error('Dimensions are different between two contour groups, cannot proceed...');
end

CONTOUR_GROUP1=CONTOUR_GROUP1(minf:maxf,mint:maxt,:);
CONTOUR_GROUP2=CONTOUR_GROUP2(minf:maxf,mint:maxt,:);

if ~isa(CONTOUR_GROUP1,'double')
	CONTOUR_GROUP1=double(CONTOUR_GROUP1);
end

if ~isa(CONTOUR_GROUP2,'double')
	CONTOUR_GROUP2=double(CONTOUR_GROUP2);
end

% create new sdi from the contour groups

disp('Forming probability densities...');

[rows1,columns1,trials1]=size(CONTOUR_GROUP1);

sdi1=mean(CONTOUR_GROUP1,3);
sdi2=mean(CONTOUR_GROUP2,3);

norm1=sum(sdi1(:).^2);
norm2=sum(sdi2(:).^2);

% get the self-sim scores

SCORES=cell(2,2);

% first idx is contour group, second is SDI

SCORES{1,1}=zeros(trials1,1);
SCORES{1,2}=zeros(trials1,1);
SCORES{2,1}=zeros(trials2,1);
SCORES{2,2}=zeros(trials2,1);

disp('Computing scores for group 1...');

for i=1:trials1
	tmp=CONTOUR_GROUP1(:,:,i);
	tmp_norm=sum(tmp(:).^2);
	SCORES{1,1}(i)=sum(sum(tmp.*sdi1))./sqrt(norm1*tmp_norm);
	SCORES{1,2}(i)=sum(sum(tmp.*sdi2))./sqrt(norm2*tmp_norm);
end

disp('Computing scores for group 2...');

for i=1:trials2
	tmp=CONTOUR_GROUP2(:,:,i);
	tmp_norm=sum(tmp(:).^2);
	SCORES{2,1}(i)=sum(sum(tmp.*sdi1))./sqrt(norm1*tmp_norm);
	SCORES{2,2}(i)=sum(sum(tmp.*sdi2))./sqrt(norm2*tmp_norm);
end
