function [TEMPLATE,FS]=zftftb_select_template(DIR,CUSTOMLOAD)

% CUSTOMLOAD must return the sound data and the sampling rate given a filename

if nargin<2
	CUSTOMLOAD=[];
end

pause(.001); % inserting 1 msec pause since uigetfile does not always open without it, not sure why...

response=[];

while isempty(response)
	[filename,pathname]=uigetfile({'*.mat';'*.wav'},'Pick a sound file to extract the template from',fullfile(DIR));
	
	[~,~,ext]=fileparts(filename);

	switch lower(ext)
		case '.mat'
			if isempty(CUSTOMLOAD)
				error('Did not specify loading function, cannot load .mat file.');
			end
			[y,fs]=CUSTOMLOAD(fullfile(pathname,filename));
		case '.wav'
			[y,fs]=wavread(fullfile(pathname,filename));
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

end

