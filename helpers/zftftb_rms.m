function RMS=zftftb_rms(DATA,FS,varargin)
%
%
%
%
%

if ~isa(DATA,'double')
  DATA=double(DATA);
end

tau=.025;
song_band=[1e3 8e3];
units='db';
nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
    case 'tau'
			tau=varargin{i+1};
    case 'song_band'
      song_band=varargin{i+1};
    case 'units'
      units=varargin{i+1};
  end
end

% boxcar

[b,a]=ellip(3,.2,40,[song_band]/(FS/2),'bandpass');

tau_smps=round(tau*FS);
smooth_filt=ones(tau_smps,1)/tau_smps;
RMS=sqrt(filter(smooth_filt,1,filtfilt(b,a,DATA).^2));

switch lower(units(1:2))
  case 'db'
    RMS=20*log10(RMS);
  case 'lo'
    RMS=log(RMS);
  otherwise
end
