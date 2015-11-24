function [TEMPLATE,FS]=zftftb_select_template(DIR,AUDIOLOAD)

% AUDIOLOAD must return the sound data and the sampling rate given a filename

if nargin<2
	AUDIOLOAD=[];
end

if nargin<1
	DIR=pwd;
end

pause(.001); % inserting 1 msec pause since uigetfile does not always open without it, not sure why...

response=[];

while isempty(response)
	[filename,pathname]=uigetfile({'*.mat';'*.wav'},'Pick a sound file to extract the template from',fullfile(DIR));

	[~,~,ext]=fileparts(filename);

	switch lower(ext)
		case '.mat'
			if isempty(AUDIOLOAD)
				error('Did not specify loading function, cannot load .mat file.');
			end
			[y,fs]=AUDIOLOAD(fullfile(pathname,filename));
		case '.wav'
			if verLessThan('matlab','8')
				[y,fs]=wavread(fullfile(pathname,filename));
			else
				[y,fs]=audioread(fullfile(pathname,filename));
			end
		otherwise
			error('Did not recognize file type!');
	end

	TEMPLATE=zftftb_spectro_navigate(y,fs);
	FS=fs;

	response2=[];
	while isempty(response2)

		response2=input('(C)ontinue with selected template or (s)elect another sound file?  ','s');

		switch lower(response2(1))
			case 'c'
				response=1;
			case 's'
				response=[];
			otherwise
				response2=[];
		end

	end
end
