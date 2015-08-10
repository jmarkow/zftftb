function [FEATURES,PARAMETERS]=zftftb_sap_score(s,FS,varargin)
%computes spectral FEATURES of a given signal
%
%


nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs');
end

len=17; % spectrogram window size
overlap=15; % spectrogram overlap

for i=1:2:nparams
	switch lower(varargin{i})
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
	end
end

% map to parameters structure

%len=round((len/1e3)*FS);
%overlap=round((overlap/1e3)*FS);
%nfft=2^nextpow2(len);

len=409;
overlap=365;
nfft=1024;

PARAMETERS.len=len;
PARAMETERS.overlap=overlap;
PARAMETERS.nfft=nfft;

% make time vector 

nsamples=length(s);

PARAMETERS.t=zftftb_specgram_dim(nsamples,len,overlap,nfft,FS);

[FEATURES.spec_deriv,FEATURES.AM,FEATURES.FM,FEATURES.entropy,...
	FEATURES.amp,FEATURES.gravity_center,FEATURES.pitch_goodness,FEATURES.pitch,...
	FEATURES.pitch_chose, FEATURES.pitch_weight]=sap_features(s,FS,'n',len,'overlap',overlap,'nfft',nfft);

