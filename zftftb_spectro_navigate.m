function [EXTRACTED_SOUND,EXTRACTED_IMAGE,TIME_POINTS]=markolab_spectro_navigate(DATA,FS)
%simple GUI for selecting a sound using its spectrogram
%
%	[EXTRACTED_SOUND,EXTRACTED_IMAGE]=spectro_navigate(DATA,DIR)
%
%
% DIR
% if given then brings up an interface to select a particular file
%
%
%

if nargin<2
	disp('Setting FS to 48e3...');
	FS=48e3;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters for constructing the spectrogram image
% overlap will define time resolution for the selection

len=20;
overlap=18;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DATA=DATA./abs(max(DATA));

% sampling rate doesn't matter here at all, just using a dummy value, 48e3

[sonogram_im,f,t]=zftftb_pretty_sonogram(DATA,FS,'len',len,'overlap',overlap,'clipping',-5,'filtering',300);
sonogram_im=flipdim(sonogram_im,1)*62;

[height,width]=size(sonogram_im);

disp('Generating interface...');

overview_fig=figure('Toolbar','none','Menubar','none');
overview_img=imshow(uint8(sonogram_im),hot);

overview_scroll=imscrollpanel(overview_fig,overview_img);
api_scroll=iptgetapi(overview_scroll);

vis_rect=api_scroll.getVisibleImageRect()

imoverview(overview_img);

EXTRACTED_SOUND=[];

rect_handle=imrect(get(overview_fig,'CurrentAxes'),[vis_rect(1)+30 vis_rect(2)+30 vis_rect(3)/2.5 vis_rect(4)-20]);

while isempty(EXTRACTED_SOUND)

	rect_position=wait(rect_handle);

	if rect_position(1)<1, rect_position(1)=1; end
	
	selected_width=rect_position(1)+rect_position(3);

	if selected_width>width, selected_width=width; end

	EXTRACTED_IMAGE=sonogram_im(:,rect_position(1):selected_width);	
	
	TIME_POINTS=t(rect_position(1):selected_width)
	extract_idxs=round([TIME_POINTS(1)*FS TIME_POINTS(end)*FS])

	temp_fig=figure('Toolbar','None','Menubar','None');imshow(uint8(EXTRACTED_IMAGE),hot);
	
	validate=[];
	while isempty(validate)
		validate=input('(D)one or (c)ontinue selecting?  ','s');
		drawnow;commandwindow;

		switch lower(validate(1))
			case 'd'
				EXTRACTED_SOUND=DATA(extract_idxs(1):extract_idxs(2));

			case 'c'
				continue;
			otherwise
				disp('Invalid response!');
				validate=[];
		end
	end
	close(temp_fig);
end

close(overview_fig);
