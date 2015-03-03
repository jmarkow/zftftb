function [FEATURES,PARAMETERS]=zftftb_song_score(s,FS,varargin)
%computes spectral FEATURES of a given signal
%
%


nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs');
end

len=34; % spectrogram window size
overlap=33; % spectrogram overlap
spec_sigma=1.5; % Gaussian timescale (in ms)
downsampling=5; % downsampling factor (skip columns)
filter_scale=10; % disk filter scale (samples, in spectrogram space)
norm_amp=1; % normalize the amplitude
song_band=[3e3 9e3];

for i=1:2:nparams
	switch lower(varargin{i})
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'spec_sigma'
			spec_sigma=varargin{i+1};
		case 'filter_scale'
			filter_scale=varargin{i+1};
		case 'downsampling'
			downsampling=varargin{i+1};
		case 'norm_amp'
			norm_amp=varargin{i+1};
		case 'song_band'
			song_band=varargin{i+1};
	end
end

% map to parameters structure

PARAMETERS.norm_amp=norm_amp;
PARAMETERS.song_band=song_band;
PARAMETERS.filter_scale=filter_scale;
PARAMETERS.spec_sigma=spec_sigma;
PARAMETERS.downsampling=downsampling;
PARAMETERS.len=len;
PARAMETERS.overlap=overlap;
PARAMETERS.fs=FS;
PARAMETERS.feature_names={'Cos(angle) from the reassignment vector',...
	'dx','dy','Smoothed spectrogram'};

len=round((len/1e3)*FS);
overlap=round((overlap/1e3)*FS);
%nfft=2^nextpow2(len)

% TODO remove dynamic allocation of feature matrix

if norm_amp
	s=s./max(abs(s));
end

t=-len/2+1:len/2;

spec_sigma=(spec_sigma/1000)*FS;

%Gaussian and first derivative as windows.
% let's remove redundant angles and gradients, maybe just cos

w=exp(-(t/spec_sigma).^2);
dw=(w).*((t)/(spec_sigma^2))*-2;
q=spectrogram(s,w,overlap,len)+eps; %gaussian windowed spectrogram
q2=spectrogram(s,dw,overlap,len)+eps; %deriv gaussian windowed spectrogram

[t,f]=zftftb_specgram_dim(length(s),len,overlap,len,FS);

lowpoint=max(find(f<=song_band(1)));
highpoint=min(find(f>=song_band(2)));

if isempty(lowpoint), lowpoint=length(f); end
if isempty(highpoint), highpoint=1; end

% add FM and pitch?

dx=(q2./q)/(2*pi); %displacement according to the remapping algorithm

% take subset of frequencies to focus on

dx=dx(lowpoint:highpoint,:);
sonogram=q(lowpoint:highpoint,:);

% larger disks really slows down compute time

H = fspecial('disk',filter_scale);

%compute local angles

s1=abs(cos(angle(dx)));

%filter the angle images.

blurred = imfilter(s1,H,'circular');
blurredcm = imfilter(log(abs(sonogram)),H,'circular');

[fx,fy]=gradient(abs(cos(angle(dx))));

sfx=imfilter(abs(fx),H,'circular');
sfy=imfilter(abs(fy),H,'circular');

v{1}=blurred;
v{2}=sfx;
v{3}=sfy;
v{4}=blurredcm;

[a,b]=size(v{1});

% downsample through summing (i.e. averaging)

for i=1:length(v)
	jj=1;
	
	%subsample the image by grouping columns

	len=length(1:downsampling:b-downsampling);
	
	FEATURES{i}=zeros(size(v{i},1),len);

	for j=1:downsampling:b-downsampling
		FEATURES{i}(:,jj)=sum(v{i}(:,j:j+downsampling),2);
		jj=jj+1;
	end
end

