Usage
=====

.. hint:: To pass parameters to any function in the toolbox use parameter/value pairs, see examples below.

Spectrograms
------------

To generate a spectrogram, use the function :code:`zftftb_pretty_sonogram`, which computes a simple multi-taper spectrogram using the Gaussian and Gaussian derivative windows.::

  >>[s,f,t]=zftftb_pretty_sonogram(audio_data,48e3,'len',80,'overlap',79.5,'clipping',[-2 2]);
  >>figure();
  >>imagesc(t,f,s);
  >>axis xy;

The :code:`len` and :code:`overlap` parameters set the length and overlap of the STFT to 80 and 79.5 milliseconds, respectively. Clipping sets the lower and upper clip to -2 and 2 (in logn units, this is the default for legacy compatibility, set the option 'units' to 'dB' to work in decibels).  Parameters for this function are given below.

========== ================================================================ ======== ==================== ===========
Parameter  Description                                                      Format   Options              Default
========== ================================================================ ======== ==================== ===========
overlap    STFT overlap (ms)                                                integer  N/A                  ``67``
len        STFT window length (ms)                                          integer  N/A                  ``70``
nfft       FFT size (samples)                                               integer  ``[] auto``          ``auto``
zeropad    Zero-pad (samples)                                               integer  ``[] none, 0 auto``  ``[]``
filtering  High-pass filter corner Fs (5-pole Elliptic)                     float    ``[] none``          ``[]``
clipping   Spectrogram clipping (logn units)                                2 floats  N/A                 ``[-2 2]``
units      Set spectrogram units                                            string   ``ln,db,lin``        ``ln``
postproc   Prettify spectrogram (non-linear)                                string   ``y,n``              ``y``
saturation Image saturation (brightness of image, postproc on only)         float    ``[0-1]``            ``.8``
========== ================================================================ ======== ==================== ===========

Sound clustering
----------------

Sound clustering is performed with zftftb_song_clust, which computes the Euclidean distance between features computed for a user-defined template, and a set of audio files.  The basic workflow is as follows:  (1) spectral features are computed for all files in a director, (2) the Euclidean distance between a template and the files is computed, (3) the user selects hits based on the distance measure.  Results for a particular template are stored in a sub-directory of your choice.  You can go back to this directory and re-run any stage of the process without having to recompute the other stages (examples are given below).  It will work with data saved in .mat files (requires a function to point to location of the data and sampling rate), or audio files.

#.  To cluster a set of .wav files use the following command.
    ::

      >>zftftb_song_clust;

#.  You should see the following outputs.
    ::

      >>zftftb_song_clust;
      >>Auto detecting file type
      >>File filter:  *.wav
      >>Would you like to go to a (p)revious run or (c)reate a new one?

#.  The file filter will use the first extension it finds in the directory. For example, if the first file in the directory is a .wav file, the script assumes all files to process are .wav files.  This can be overridden through any of the script options detailed below.  If you choose to (c)reate a new run, you will be asked to name the sub-directory to store results in.
#.  After this, you will then need to select an audio file (anywhere on the computer) that contains the template.  Once the file is selected, you will be presented with a GUI to tell the program exactly where the template is in time.
#.  Finally, you will perform a manual cluster cut on the Euclidean distances between the template and the data.  Note that the distances have been inverted, so higher numbers indicate a closer match.

Parameters for zftftb_song_clust are given below.

========== ================================================================ ======== ==================== =============
Parameter  Description                                                      Format   Options              Default
========== ================================================================ ======== ==================== =============
colors     colormap to use for spectrograms                                 string   MATLAB colormaps     ``hot``
len        STFT window length for spectrograms (ms)                         integer  N/A                  ``34``
overlap    STFT overlap (ms)                                                integer  N/A                  ``33``
disp_band  STFT frequency range                                             2 ints   N/A                  ``[1 10e3]``
audio_load Anonymous function used for loading audio data from .mat files   anon     N/A
data_load  Anonymous function used for loading data to align                anon     N/A
file_filt  File extension filter                                            string   ``auto,wav,mat``      ``auto``
extract    Extract .gif, .wav, and .mat files post-alignment                logical  N/A                  ``true``
clust_lim  Limit on number of points to show for cluster cutting            integer  N/A                  ``1e4``
========== ================================================================ ======== ==================== =============

Song detection
--------------

Under construction.

Spectral density images
-----------------------

Under construction.
