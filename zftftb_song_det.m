function [SONG_IDX,T]=zftftb_song_det(AUDIO,FS,varargin)
%based on Andalmann's algorithm

if nargin<2
	disp('Setting FS to 30e3...');
	FS=30e3;
end

% the template cutoff could be defined by the 95th prctile of the abs(noise) magnitude

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

len=.005; % window length (s)
song_band=[2e3 6e3];
overlap=0; % overlap (s)
song_duration=.8; % smoothing (s) 
ratio_thresh=2; % ratio song:nonsong
pow_thresh=-inf; % power threshold (au)
song_thresh=.2; % song threshold
songpow_thresh=.8;
silence=0;

for i=1:2:nparams
	switch lower(varargin{i})
		case 'song_band'
			song_band=varargin{i+1};
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'song_duration'
			song_duration=varargin{i+1};
		case 'ratio_thresh'
			ratio_thresh=varargin{i+1};
		case 'song_thresh'
			song_thresh=varargin{i+1};
		case 'pow_thresh'
			pow_thresh=varargin{i+1};
		case 'songpow_thresh'
			songpow_thresh=varargin{i+1};
		case 'silence'
			silence=varargin{i+1};

	end
end

len=round(len*FS);
overlap=round(overlap*FS);

if isempty(pow_thresh)
    pow_thresh=0;
end

[s,f,T]=spectrogram(AUDIO,len,overlap,[],FS);

% take the power and find our FS band

power=abs(s);
min_idx=max(find(f<=song_band(1)));
max_idx=min(find(f>=song_band(2)));

% take the song/nonsong power ratio

song=mean(power(min_idx:max_idx,:),1);
nonsong=mean(power([1:min_idx-1 max_idx+1:end],:),1)+eps;

song_ratio=song./nonsong;
%song_detvec=smooth(double(song_ratio>ratio_thresh),round((FS*song_duration)/(len-overlap)));

% convolve with a moving average filter

filt_size=round((FS*song_duration)/(len-overlap));
mov_filt=ones(1,filt_size)*1/filt_size;

if ~silence
	song_detvec=conv(double(song_ratio>ratio_thresh),mov_filt,'same');
	pow_detvec=conv(double(song>pow_thresh),mov_filt,'same');
else
	song_detvec=conv(double(song_ratio<ratio_thresh),mov_filt,'same');
	pow_detvec=conv(double(song<pow_thresh),mov_filt,'same');
end


% where is the threshold exceeded for both the raw power and the ratio?

pow_idx=pow_detvec>songpow_thresh;
ratio_idx=song_detvec>song_thresh;

%%%%


SONG_IDX=pow_idx&ratio_idx;

