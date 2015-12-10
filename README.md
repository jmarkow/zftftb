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

Sound clustering is performed with zftftb_song_clust, which computes the Euclidean distance between features computed for a user-defined template, and a set of audio files.  It will work with data saved in .mat files (requires a function to point to location of the data and sampling rate), or audio files.  To cluster a set of .wav files use the following command

```
zftftb_song_clust;
```

###Spectral Density Images

###Song detection
