# pico8_fftsampler
Initial stab at building a sampler/compressor for digital audio playback in Pico-8.

ARGUMENTS: sample-filename audio-sample-rate outputfile

ex:
lua pico8_fftsampler samples.txt 44100 outp8.txt

Requires LuaFFT. To install:

```
luarocks install luafft
```

Instructions:

1) Choose an audio file and prefilter it so that it only includes frequencies higher than 60Hz and lower than 2600Hz, which is the range of frequencies that can be reproduced by the Pico-8. (Your favorite audio editor should have high-pass and low-pass filters.)
2) Export raw sample data from the audio file. (This can be done with Audacity's "Sample Data Export" feature.)
3) Process sample data with pico8_fftsampler.
4) Copy output into code block of picodigi.p8 and run.
