function [EXTRACTED_SOUND,EXTRACTED_IMAGE,TIME_POINTS,EXTRACT_IDXS,FREQ_POINTS]=zftftb_spectro_navigate(DATA,FS,WIDTH,HEIGHT)
%simple GUI for selecting time points in sound data based on the spectrogram
%
%	[EXTRACTED_SOUND,EXTRACTED_IMAGE]=zftftb_spectro_navigate(DATA,FS)
%
%	DATA
%	sound data
%
%	FS
%	sampling rate
%
%the program returns the following output:
%
%	EXTRACTED_SOUND
%	the selected sound data
%
%	EXTRACTED_IMAGE
%	the selected segment of the spectrogram
%
%	TIME_POINTS
%	two element vector indicating the left/right edges of the selected segment
%
%

if nargin<4
	HEIGHT=[];
end

if nargin<3
	WIDTH=[];
end

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

%DATA=DATA./abs(max(DATA));

% sampling rate doesn't matter here at all, just using a dummy value, 48e3
% TODO: first double click to place rectangle to prevent too much scrolling

[sonogram_im,f,t]=zftftb_pretty_sonogram(DATA,FS,'len',len,'overlap',overlap,'clipping',[-3 2],'filtering',300,'norm_amp',1);
sonogram_im=flipdim(sonogram_im,1)*62;

[height,width]=size(sonogram_im);

disp('Generating interface...');

overview_fig=figure('Toolbar','none','Menubar','none');
overview_img=imshow(uint8(sonogram_im),hot);

overview_scroll=imscrollpanel(overview_fig,overview_img);
api_scroll=iptgetapi(overview_scroll);

vis_rect=api_scroll.getVisibleImageRect();
imoverview(overview_img);

EXTRACTED_SOUND=[];

initial_position=[vis_rect(1)+30 vis_rect(2)+30 vis_rect(3)/2.5 vis_rect(4)-20];

if ~isempty(WIDTH)

	% width specified in time, how many pixels?

	timestep=mean(diff(t));
	width_pixels=round(WIDTH./timestep);
	initial_position(3)=width_pixels;
end

if ~isempty(HEIGHT)
	initial_position(4)=HEIGHT;
end

rect_handle=imrect(get(overview_fig,'CurrentAxes'),initial_position);

if ~isempty(WIDTH) & ~isempty(HEIGHT)
	setResizable(rect_handle,false);
end

while isempty(EXTRACTED_SOUND)

	rect_position=wait(rect_handle);

	if rect_position(1)<1, rect_position(1)=1; end
	if rect_position(2)<1, rect_position(2)=1; end

	rect_position=round(rect_position);

	selected_width=rect_position(1)+rect_position(3);
	selected_height=rect_position(2)+rect_position(4);

	if selected_width>width, selected_width=width; end
	if selected_height>=height, selected_height=height-1; end

	EXTRACTED_IMAGE=sonogram_im(:,rect_position(1):selected_width);

	TIME_POINTS=t(rect_position(1):selected_width);
	FREQ_POINTS=f(end-selected_height:end-rect_position(2));

	EXTRACT_IDXS=round([TIME_POINTS(1)*FS TIME_POINTS(end)*FS]);

	temp_fig=figure('Toolbar','None','Menubar','None');imshow(uint8(EXTRACTED_IMAGE),hot);

	validate=[];
	while isempty(validate)
		validate=input('(D)one or (c)ontinue selecting?  ','s');
		drawnow;commandwindow;

		switch lower(validate(1))
			case 'd'
				EXTRACTED_SOUND=DATA(EXTRACT_IDXS(1):EXTRACT_IDXS(2));

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
