function [RMASK IMASK q]=zftftb_contour_approx(SIGNAL,FS,varargin)
%zftftb_contour_approx computes the contour approximation via Chris' method.
%
%	[REMASK IMASK q]=zftftb_contour_approx(SIGNAL,varargin)
%
%	SIGNAL
%	vector that contains the signal of interest
%
%	the following additional parameters may be specified as parameter/value pairs
%
%		N
%		length of the window for spectrogram (default: 2048)
%
%		overlap
%		window overlap (overlap<N) (default: 2030)
%
%		tscale
%		timescale of filtering in ms (default: 1.5ms)
%
%		FS
%		sampling rate (default: 48e3)
%

if nargin<2
	FS=48e3;
end

len=68;
overlap=67;
tscale=1.5;
nfft=[];

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'len'
			len=varargin{i+1};
		case 'nfft'
			nfft=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'tscale'
			tscale=varargin{i+1};
		otherwise
	end
end

if isempty(nfft)
	nfft=len;
end

len=round((len/1e3)*FS);
nfft=2^nextpow2(round((nfft/1e3)*FS));
overlap=round((overlap/1e3)*FS);

t=-len/2+1:len/2;

sigma=(tscale/1e3)*FS;

w = exp(-(t/sigma).^2);
dw = -2*w.*(t/(sigma^2));

q = spectrogram(SIGNAL,w,overlap,nfft) + eps;
q2 = spectrogram(SIGNAL,dw,overlap,nfft) + eps;
dx = (q2./q)/(2*pi);

redx = real(dx)./abs(real(dx));
imdx = imag(dx)./abs(imag(dx));

RMASK = redx - circshift(redx,[1 0]) ~= 0 | redx - circshift(redx,[0 1]) ~= 0;
IMASK = imdx - circshift(imdx,[1 0]) ~= 0 | imdx - circshift(imdx,[0 1]) ~= 0;
