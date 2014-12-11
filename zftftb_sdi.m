function [SDI F T]=zftftb_sdi(MIC_DATA,FS,varargin)
%computes a contour histogram (or spectral density image, SDI) for a group of sounds
%
%	HISTOGRAM=zftftb_sdi(MIC_DATA,varargin)
%
%	MIC_DATA
%	samples x trials matrix of aligned sounds
%	
%	the following may be specified as parameter/value pairs:%
%		
%		FS
%		sampling frequency (default: 25e3)
%
%		tscale
%		time scale for Gaussian window for the Gabor transform (in ms, default: 1.5)
%	
%		n
%		window length
%
%		nfft
%		number of points in fft
%
%		overlap
%		window overlap
%
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETER COLLECTION %%%%%%%%%%%%%%%%%

if nargin<2
	disp('Setting FS to 48e3...');
	FS=48e3;
end

if nargin<1
	error('ephysPipeline:tfhistogram:notenoughparams','Need 1 argument to continue, see documentation');
end

nparams=length(varargin);

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

tscale=1.5;
len=34;
nfft=34;
overlap=33;
filtering=500; % highpass for mic trace
mask_only=0;
spect_thresh=.75;
norm_amp=1;
weighting='log';

for i=1:2:nparams
	switch lower(varargin{i})
		case 'tscale'
			tscale=varargin{i+1};
		case 'len'
			len=varargin{i+1};
		case 'nfft'
			nfft=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'filtering'
			filtering=varargin{i+1};
		case 'mask_only'
		    	mask_only=varargin{i+1};
		case 'spect_thresh'
		    	spect_thresh=varargin{i+1};
	    	case 'norm_amp'
			norm_amp=varargin{i+1};
		case 'weighting'
			weighting=varargin{i+1};
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the contour histogram
% normalize the mic trace

% 

[nsamples,ntrials]=size(MIC_DATA);

if ~isempty(filtering)
	disp(['Filtering signals with corner Fs ' num2str(filtering) ]);
	[b,a]=ellip(4,.2,40,[filtering/(FS/2)],'high');
	MIC_DATA=filtfilt(b,a,MIC_DATA);
end

if norm_amp
	disp('Normalizing amplitudes...');
	MIC_DATA=MIC_DATA./repmat(max(abs(MIC_DATA),[],1),[nsamples 1]);
end

[rmask_pre imask_pre spect]=zftftb_contour_approx(MIC_DATA(:,1),FS,...
	'len',len,'overlap',overlap,'tscale',tscale,'nfft',nfft);

if mask_only
	RMASK=rmask_pre./ntrials;
	IMASK=imask_pre./ntrials;
else
	RMASK=((rmask_pre.*abs(spect))>spect_thresh)./ntrials;
	IMASK=((imask_pre.*abs(spect))>spect_thresh)./ntrials;
end

[rows,columns]=size(rmask_pre);

re_contours=zeros(rows,columns,ntrials,'uint8');
im_contours=zeros(rows,columns,ntrials,'uint8');

re_contours(:,:,1)=uint8(rmask_pre);
im_contours(:,:,1)=uint8(imask_pre);

% leave user to specify number of workers

for i=1:ntrials

	[rmask_pre imask_pre spect]=zftftb_contour_approx(MIC_DATA(:,i),FS,'len',len,'overlap',overlap,'tscale',tscale,'nfft',nfft);

	% log weighting

	switch lower(weighting(1:3))
		case 'log'
			weights=log(abs(spect));
			weights=weights-min(weights(:));
			weights=weights./max(weights(:));
		case 'lin'
			weights=abs(spect);
		otherwise
			error('Did not understand weighting.');
	end

	re_contours(:,:,i)=uint8(rmask_pre);
	im_contours(:,:,i)=uint8(imask_pre);

	if mask_only
		RMASK=RMASK+rmask_pre./ntrials;
		IMASK=IMASK+imask_pre./ntrials;
	else
		RMASK=RMASK+(((rmask_pre.*weights)>spect_thresh))./ntrials;
		IMASK=IMASK+(((imask_pre.*weights)>spect_thresh))./ntrials;
	end

end

[rows,cols]=size(RMASK);

SDI.re=RMASK;
SDI.im=IMASK;

len=round((len/1e3)*FS);
overlap=round((overlap/1e3)*FS);

% shamelessly cribbed from MATLAB's computation for spectrogram

% should scale 1:fbins * nyquist

F=((1:rows)./rows).*(FS/2);

% starting at 1 one hop is n-overlap samples

col_idx=1+(0:(cols-1))*(len-overlap);

% then in time each step is samples + window/2 ofFSet /SR

T=((col_idx-1)+((len/2)'))/FS;
