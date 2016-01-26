function zftftb_install()
% run this script to add appropriate directories to the MATLAB path, also handles
% dependencies
%

% where are we?

cur_file=mfilename('fullpath');
[cur_path,~,~]=fileparts(cur_file);

% name of package

package_name='zftftb';

% dependencies

dependency(1).name='markolab';
dependency(1).chk='markolab_multi_fig_save';
dependency(1).url='https://github.com/jmarkow/markolab.git';
dependency(1).basedir='';

dependency(2).name='robofinch';
dependency(2).chk='robofinch_agg_data';
dependency(2).url='https://github.com/jmarkow/robofinch.git';
dependency(2).basedir='';

dependency(3).name='zftftb';
dependency(3).chk='';
dependency(3).url='';
dependency(3).basedir=cur_path;

% dirs to skip

skip_dirs={'.git','docs'};

if ~isunix
  error('Install script only works on OS X or Linux.');
end

% check for git

status=unix('git version');

if status~=0
  error('Git must be installed before continuing.');
end

% check for markolab dependency

fprintf('Checking dependencies...\n')

matlab_path=regexp(path,'\:','split');
package_added=strfind(matlab_path,cur_path);
idx=cellfun(@(x) ~isempty(x),package_added);
package_added=any(idx);

for i=1:length(dependency)

  package_flag=strcmp(dependency(i).name,package_name);

  if (package_flag&~package_added) | ...
    (~isempty(dependency(i).chk)&isempty(which(dependency(i).chk)))

    if isempty(dependency(i).basedir)
      tmp=uigetdir(fullfile(pwd,'..'),'Select directory to place repository in');
      dependency(i).basedir=tmp;
    end

    if ~exist(fullfile(dependency(i).basedir,dependency(i).name),'dir') & ~package_flag
      if ~isempty(dependency(i).url)
        status=unix(['git clone ' dependency(i).url ' ' ...
        fullfile(dependency(i).basedir,dependency(i).name)]);
      end
    else
      fprintf('Directory already exists, adding to MATLAB path...\n')
    end

    if status~=0
      error('Error installing dependency %s',dependency(i).name);
    end

    if package_flag
      tmp=genpath(cur_path);
    else
      tmp=genpath(fullfile(dependency(i).basedir,dependency(i).name));
    end

    splits=regexp(tmp,'\:','split');

    for j=1:length(skip_dirs)
      idx=cellfun(@(x) ~isempty(x),strfind(splits,skip_dirs{j}));
      splits(idx)=[];
    end

    emptyidx=cellfun(@isempty,splits);
    splits(emptyidx)=[];

    newstr='';

    for j=1:length(splits)
      newstr=[newstr splits{j} ':'];
    end

    addpath(newstr);
    status=savepath;

    if status~=0
      error('Error saving new MATLAB path, make sure pathdef.m is writable');
    end

    fprintf('%s installed successfully\n',dependency(i).name);
  else
    fprintf('Dependency %s already installed\n',dependency(i).name)
  end
end
