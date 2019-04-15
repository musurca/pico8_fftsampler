luafft = require "luafft"

p8_pitches={65.41,69.30,73.42, 77.78,82.41, 87.31, 92.50,98.00,103.83,110.00,116.54,123.47,130.81,138.59,146.83,155.56,164.81,174.61,185.00,196.00,207.65,220.00,233.08,246.94,261.63,277.18,293.66,311.13,329.63,349.23,369.99,392.00,415.30,440.00,466.16,493.88,523.25,554.37,587.33,622.25,659.25,698.46,739.99,783.99,830.61,880.00,932.33,987.77,1046.50,1108.73,1174.66,1244.51,1318.51,1396.91,1479.98,1567.98, 1661.22,1760.00,1864.66,1975.53,2093.00,2217.46,2349.32,2489.02}

function find_nearest_p8_note(freq)
  local n,dist=-1,9999
  local d
  for i=1,#p8_pitches do
    d=math.abs(freq-p8_pitches[i])
    if d<dist then
      n=i
      dist=d
    end
  end
  return n
end

function next_possible_size(n)
  local m = n
  while (1) do
    m = n
    while m%2 == 0 do m = m/2 end
    while m%3 == 0 do m = m/3 end
    while m%5 == 0 do m = m/5 end
	if m <= 1 then break end
    n = n + 1
  end
  return n
end

function devide(list, factor)
  for i,v in ipairs(list) do list[i] = list[i] / factor end
end

function perform_fft(s)
  local fftsamps={}
  --real to complex numbers
  for i=1,#s do
    fftsamps[i]=complex.new(s[i],0)
  end
  --do FFT
  local r=luafft.fft(fftsamps,false)
  devide(r,#s/2)

  --return spectrum amplitudes as complex numbers
  return r
end

function spairs(t, order)
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end
  if order then
      table.sort(keys, function(a,b) return order(t, a, b) end)
  else
      table.sort(keys)
  end
  local i = 0
  return function()
      i = i + 1
      if keys[i] then
          return keys[i], t[keys[i]]
      end
  end
end

--Hanning window function
function hanning(i,len)
  return (1 -  math.cos(2*math.pi*i/len))/2
end

function init()
  if #arg<3 then
    print("ARGUMENTS: filename audio-sample-rate outputfile\n\nex: samples.txt 44100 outp8.txt")
    os.exit()
  end
  filename=arg[1]
  samplerate=tonumber(arg[2])
  outputfile=arg[3]
end

function load_samples(src)
 local samples={}
 file = io.open(src,"r")
 io.input(file)
 local ln=1
 for line in io.lines() do
  samples[#samples+1] = tonumber(line)
 end
 file:close()

 slicesize_raw=math.floor(samplerate/30)
 slicesize=next_possible_size(slicesize_raw)
 length=slicesize/samplerate

 return samples
end

function output_notes(output,outfile)
  file = io.open(outfile,"w")
  io.output(file)
  io.write("snd={")
  for i=1,#output do
    local sl=output[i]
    io.write("{")
    for v=1,#sl do
      io.write(sl[v])
      if v<#sl then io.write(",") end
    end
    io.write("}")
    if i<#output then io.write(",") end
  end
  io.write("}")
  file:close()
 end

function normalize_volume(output)
  local v
  for i=1,#output do
    v=output[i]
    local maxvol=0
    for k=2,#v,2 do
      if v[k]>maxvol then
        maxvol=v[k]
      end
    end
    if maxvol > 0 then
      for k=2,#v,2 do
       v[k]=math.floor(6*v[k]/maxvol)+1
      end
    end
  end
end

function do_spectral_analysis(samples)
  local output={}
  local slice={}
  local slicenum=1
  function clear_slice()
    for i=1,slicesize do
      slice[i]=0
    end
  end

  --do full analysis first to find valid frequencies
  local samplesfft={}
  local spectrum={}
  local validnotes={}
  for i=1,64 do
    validnotes[i] = false
  end
  local k,f
  local fullsz=next_possible_size(#samples)
  local ln=fullsz/samplerate
  for i=1,#samples do
    samplesfft[i]=samples[i]*hanning(i,fullsz)
  end
  for i=#samples+1,fullsz do
    samplesfft[i]=0
  end
  spectrum=perform_fft(samplesfft)
  for i=1,#spectrum/2 do
    k=complex.abs(spectrum[i])
    k=k*100
    if k>10 then --if k>0.99 then
      f=find_nearest_p8_note((i-1)/ln)
      validnotes[f]=true
      print((f-1)..": "..k)
    end
  end
  samplesfft={} -- delete

  --do slice analysis and convert to Pico-8 notes
  local samp_index,samp_end=1
  while samp_index<=#samples do
    samp_end=samp_index+slicesize-1
    if samp_end>#samples then
     samp_end=#samples
     clear_slice()
    end
    for i=samp_index,samp_end do
      slice[i-samp_index+1]=samples[i]--complex.new(samples[i]*hanning((i-samp_index+1),slicesize),0)
    end
    spectrum=perform_fft(slice)
    local start=math.floor(65*length)+1
    local final=math.floor(2490*length)+1
    local notes={}
    --print("Slice #"..slicenum.."\n--------------")
    for i=start,final do
      k=complex.abs(spectrum[i])
      k=k*k*100
      f=find_nearest_p8_note((i-1)/length)
      if k>1 and validnotes[f] then
      --if (k>1 and validnotes[f]) then
      --if k>1 then
        if notes[f]==nil then
          notes[f]=k
        else
          if notes[f]<k then
            notes[f]=k
          end
        end
        --f=(i-1)/length
        --print(f.."Hz : "..k.." (P8 Note: "..(f-1)..")")
      end
    end
    local maxchannels=4
    local noteslice={}
    --sort notes by order of descending amplitude and write out top 4
    for k,v in spairs(notes, function(t,a,b) return t[b] < t[a] end) do
      noteslice[#noteslice+1]=k-1
      noteslice[#noteslice+1]=v
      maxchannels=maxchannels-1
      if maxchannels==0 then break end
    end
    output[#output+1]=noteslices
    --print("--------------")
    samp_index=samp_end+1
    slicenum=slicenum+1
  end

  return output
end

run_starttime=os.clock()
init()

print("Loading samples...")
samps=load_samples(filename)

print("Performing spectral analysis...")
notesout=do_spectral_analysis(samps)

print("Outputting audio for P8...")
normalize_volume(notesout)
output_notes(notesout,outputfile)
print("Done! ("..(os.clock()-run_starttime).." seconds)")