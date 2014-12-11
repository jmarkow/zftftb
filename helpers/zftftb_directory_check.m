function PROC_DIR=zftftb_directory_check(DIR,EXT)

if nargin<2
	EXT='MANUALCLUST';
end

listing=dir(fullfile(DIR));
prev_run_listing={};

for i=1:length(listing)
	if listing(i).isdir & listing(i).name~='.'
		prev_run_listing{end+1}=listing(i).name;
	end
end

PROC_DIR=[];

% check for previous runs

if ~isempty(prev_run_listing)
	response=[];
	while isempty(response)
		response=input('Would you like to go to a (p)revious run or (c)reate a new one?  ','s');
		
		switch lower(response(1))

			case 'p'
				dir_num=menu('Which directory would you like to use?',prev_run_listing);

				if isempty(dir_num), continue; end

				dir_name=prev_run_listing{dir_num};
				PROC_DIR=fullfile(DIR,dir_name);

			case 'c'

			otherwise
				response=[];
		end

	end
end

% prompt the user for a directory name if necessary

if isempty(PROC_DIR)

	dir_name=[];

	while isempty(dir_name)

		dir_name=input('What would you like to name the new directory?  ','s');

		if exist(fullfile(DIR,dir_name),'dir')
			warning('ephysPipeline:ephysCluster:direxist','Directory exists!');
			dir_name=[];
		end

	end

	PROC_DIR=fullfile(DIR,[ dir_name '_' EXT ]);
	mkdir(PROC_DIR);

end
