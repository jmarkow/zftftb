Installation
=============

Note that this assumes a passing familiarity with the command line and git.  If you are unfamiliar, google "command line tutorial" and "git tutorial" (hard-linking to specific tutorials would be a fool's errand at this point).  

Simply clone the ZFTFTB github repository, and add the directory and subdirectories to your MATLAB path (including any dependencies, see below).  An installation script is included that automates the entire process.

Requirements
------------

This has been tested using MATLAB 2010A and later on Windows and Mac (Linux should be fine). You must have the `markolab <https://github.com/jmarkow/markolab/>`_ and `robofinch <https://github.com/jmarkow/robofinch/>`_ toolboxes in your MATLAB path. The only MATLAB Toolbox required is the Signal Processing toolbox, which is typically included in most standard installations.  It is highly recommended that you have git installed for ease of installation and managing dependencies.

Using the install script
------------------------

First clone the repository somewhere reasonable using the terminal (Linux/OS X)::

	$git clone https://github.com/jmarkow/zftftb.git

If you are running MATLAB on Linux or OS X, a script is available to automatically add ZFTFTB and any necessary dependencies to your MATLAB path.  First, navigate to the cloned repository or unzipped directory of files from the github repository::

  >>cd some_directory/zftftb/
  >>zftftb_install

You should be prompted to select a base directory for dependencies (e.g. ``~/Documents/MATLAB``).  Then, assuming git is installed and your pathdef.m is writable, the rest should be taken care of for you.

Manual installation
-------------------

If you are somewhat comfortable with the command line and MATLAB, manual installation shouldn't be too onerous.  If you are working with OS X or Linux, pop open a terminal and clone the ZFTFTB and Markolab repositories::

  $git clone https://github.com/jmarkow/zftftb.git
  $git clone https://github.com/jmarkow/markolab.git
  $git clone https://github.com/jmarkow/robofinch.git

Then, make sure the repositories and their sub-directories are added to the MATLAB path.
