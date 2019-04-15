# pico8_fftsampler
Initial stab at building a sampler for digital audio playback in Pico-8.

ARGUMENTS: sample-filename audio-sample-rate outputfile

ex:
lua pico8_fftsampler samples.txt 44100 outp8.txt

Requires LuaFFT. To install:

```
luarocks install luafft
```

Instructions:

1) Export raw sample data from an audio file. This can be done with Audacity's "Sample Data Export" feature.
2) Process sample data with pico8_fftsampler.
3) Copy output into code block of picodigi.p8 and run.
