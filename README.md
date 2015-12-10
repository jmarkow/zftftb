# Welcome (i.e. what does this do?)

This is a MATLAB toolbox of time-frequency tools, some of which are based on the Gardner & Magnasco reassignment technique, and the newer contour based technique of Lim & Gardner.  Also, these functions depend on the [markolab .m files](https://github.com/jmarkow/markolab) being in your MATLAB path.  See the wiki for details.

# Table of Contents

1. [Requirements](#requirements)
2. [Spectrograms](#spectrograms)
3. [Sound clustering](#sound-clustering)
4. [Spectral density images](#spectral-density-images)
5. [Quantifying sound similarity](#sound-similarity)
6. [Song detection](#song-detection)
6. [Full list of function options](#full-options)

###Requirements

This has been tested using MATLAB 2010A and later on Windows and Mac (Linux should be fine). You must have the [markolab](https://github.com/jmarkow/markolab) toolbox in your MATLAB path. The only MATLAB Toolbox required is the Signal Processing toolbox.

###Spectrograms

To generate a spectrogram, use the function zftftb_pretty_sonogram, which computes a simple multi-taper spectrogram using the Gaussian and Gaussian derivative windows.

```
>>[s,f,t]=zftftb_pretty_sonogram(audio_data,48e3,'len',80,'overlap',79.5,'clipping',[-2 2]);
>>figure();
>>imagesc(t,f,s);
>>axis xy;
```

The `len` and `overlap` parameters set the length and overlap of the STFT to 80 and 79.5 milliseconds, respectively.  Clipping sets the lower and upper clip to -2 and 2 (in logn units, this is the default for legacy compatibility, set the option 'units' to 'dB' to work in decibels).

| Parameter | Description | Format | Options | Default |
|-----------|-------------|--------|---------|---------|
| `overlap` | STFT overlap (ms) | integer | N/A | `67` |
| `len` | STFT window length (ms) | integer | N/A | `70` |
| `nfft` | FFT size (samples) | integer | empty to set automatically | `` |
| `zeropad` | Zero-pad (samples)| integer | integer, or 0 for auto-pad, empty for no zeropad | `` |
| `filtering` | High-pass filter corner Fs (5-pole Elliptic) | float | empty for no filtering | `` |
| `clipping` | Spectrogram clipping (logn units) | 2 element vector, floats | N/A | [-2 2] |
| `units` | Set spectrogram units | string | 'ln','db', otherwise linear | 'ln' |
| `postproc` | Prettify spectrogram (non-linear) | string | 'y','n' | 'y' |
| `saturation` | Image saturation (brightness of image, only use with postproc on) | float | [0-1] | '.8' |


###Sound Clustering

Sound clustering is performed with zftftb_song_clust, which computes the Euclidean distance between features computed for a user-defined template, and a set of audio files.  The basic workflow is as follows:  (1) spectral features are computed for all files in a director, (2) the Euclidean distance between a template and the files is computed, (3) the user selects hits based on the distance measure.  Results for a particular template are stored in a sub-directory of your choice.  You can go back to this directory and re-run any stage of the process without having to recompute the other stages (examples are given below).  It will work with data saved in .mat files (requires a function to point to location of the data and sampling rate), or audio files.  

1. To cluster a set of .wav files use the following command
```
zftftb_song_clust;
```
1. You should see the following outputs
```
>>zftftb_song_clust;
Auto detecting file type
File filter:  *.XXX
Would you like to go to a (p)revious run or (c)reate a new one?
```
The file filter will use the first extension it finds in the directory. For example, if the first file in the directory is a .wav file, the script assumes all files to process are .wav files.  This can be overridden through any of the script options detailed below.  If you choose to (c)reate a new run, you will be asked to name the sub-directory to store results in.  

1. After this, you will then need to select an audio file (anywhere on the computer) that contains the template.  Once the file is selected, you will be presented with a GUI to tell the program exactly where the template is in time.
1. Finally, you will perform a manual cluster cut on the Euclidean distances between the template and the data.  Note that the distances have been inverted, so higher numbers indicate a closer match.  

| Parameter | Description | Format | Options | Default |
|-----------|-------------|--------|---------|---------|
| `colors` | Colormap to use for spectrograms | string | MATLAB colormaps | `hot` |
| `len` | STFT window length for spectrograms (ms) | integer | N/A | `34` |
| `overlap` | STFT overlap (ms) | integer | N/A | `33` |
| `disp_band` | STFT overlap frequency range | 2 element vector of integers | N/A | `[1 10e3]` |
| `audio_load` | Function for reading in .mat files (not needed for audio files), must return data and sampling rate | Anonymous function with two outputs | N/A | `` |
| `data_load` | Function for reading data from .mat files (not needed for audio files), must return data and sampling rate | Anonymous function with two outputs | N/A | `` |
| `file_filt` | Extension of files to process | String | `auto` to automatically determine, otherwise use extension, e.g. `wav` | `auto` |
| `extract` | Save matches in .gif, .wav, and .mat formats | Logical | N/A | `1` |
| `clust_li` | Maximum number of points to show for cluster cutting | Integer | N/A | `1e4` |

Parameters for feature calculation.

| Parameter | Description | Format | Options | Default |
|-----------|-------------|--------|---------|---------|
| `filter_scale` | STFT smoothing parameter (pixels, disk filter) | integer | N/A | `10` |
| `downsampling` | STFT time downsampling factor | integer | N/A | `5` |
| `spec_sigma` | STFT Gaussian window timescale (ms)| float | N/A | '1.5' |
| `norm_amp` | Normalize amplitudes prior to feature calculation| logical | N/A | '0' |


###Spectral Density Images

Spectral density images are computed using zftftb_sdi.

###Song detection

Song detection is performed with zftftb_song_det.
