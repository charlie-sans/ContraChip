# ContraChip

A Contract (`exe`) project that drives the **OwnaudioNET** audio engine from
Contract code through a C# bridge host.

The Contract side imports the reusable surface (`import OwnAudioSharp;`) over a
C# host assembly containing four bindings:
`OwnAudio` (engine lifecycle + config), `FileSource`, `AudioMixer` and `Chip`
(the chiptune synth engine).

- **Shadowing**: the bridge is the C# "minimum"; the shadow contracts win for
  members they declare (IL) and fall back to the host for the rest, so extra
  IL-only surface (`InitDemo`, `Open`, `Loop`) is added in Contract, not C#.
- **Object handles**: `FileSource`/`AudioMixer`/`Chip` cross the boundary as
  opaque CLR `object` handles held in a private `handle` field (exactly the
  stdlib `DateTime` pattern) — no integer IDs or registries. Each Contract
  instance method forwards its handle to a host static (`host.Play(this.handle)`).
- **Programmatic output**: `OwnAudio.Send(ManagedPtr<float>, sampleCount)` and
  `OwnAudio.SendFrames(ManagedPtr<float>, frames)` push rendered audio to the
  output device zero-copy. The `&buffer`/`Address()` native pointer of a
  `ManagedPtr<float>` crosses to a bridge static that spans it as
  `ReadOnlySpan<float>` and calls `OwnaudioNet.Send`.
- **Streaming raw PCM**: `OwnAudio.Stream(framesPerCall, totalFrames, hz)` is an
  IL-only producer that generates a tone straight into a `ManagedPtr<float>`
  block and paces pushes against the engine's output ring buffer
  (`OutputBufferAvailable` / `OutputRingFrames`), so a real-time stream never
  overruns. On a real (non-mock) device the ≤ block-duration sleep paces the
  push to wall-clock; under the mock engine the ring is not back-pressure
  signalled, so the helper uses a short capped wait and still sends (never
  deadlocks). Device routing is explicit via
  `OwnAudio.SetOutputDeviceByName(name)` (ignored/returns false on a mock
  engine; the system default is used otherwise).
- Audio rendering (float buffers) stays C#-side for Sources/Mixers because
  `Span<float>` cannot cross the boundary; the `Send` path hands only the
  native pointer across and pushes from the bridge.
- **The chip engine lives in C#.** All waveform synthesis, offline rendering
  and MIDI sequencing is implemented once in
  `../OwnAudioSharp.Contract/bridge/ChipSynthBridge.cs`
  (public static `ChipSynth` + `Wave` enum), so C# and Contract consumers share
  one engine. `src/Chip.ct` in the library only forwards a `<ShadowBinding>`
  surface; this repo's `src/main.ct` calls e.g.
  `Chip.PlayNote(72, Wave.Square, 0.3, 0.5)` and
  `Chip.PlayMidiFile("assets/song.mid", Wave.Square, 0.4, 0.5)`; the C# engine
  loads the MIDI itself (tempo-aware) and streams it.

## Run the demo

```powershell
.\run.ps1
```

This builds the ownaudio bridge host in `../OwnAudioSharp.Contract/bridge/` and
runs:

```
ccl --bind ../OwnAudioSharp.Contract/bridge/bin/Debug/net10.0/OwnAudioSharp.Contract.dll src/main.ct
```

The runner is cross-platform: on Linux/macOS just use
`pwsh ./run.ps1`. The bridge stages the platform-correct native FFI for the
build host (Windows `ownaudio_ffi.dll`, Linux `libownaudio_ffi.so`,
macOS `libownaudio_ffi.dylib`), so real audio works on all three. The Ownaudio
MIDI parser libs (`OwnAudio.Midi.dll` + `libownaudio_midi_ffi.so`) are staged
too.

The demo first tries the real audio device; if none is available it falls back
to the **mock** engine (no sound card required), lists the output device,
tours every `Chip` waveform, plays melodies/chords/slides/crushes, plays
`assets/song.mid` through the engine, and shuts down cleanly.

Note: `ccl build --run` does not forward `--bind`, so host bindings are driven
through the direct `ccl --bind` invocation (as above).

## Layout

- `../OwnAudioSharp.Contract/bridge/` — host bridge assembly (this repo only
  consumes it).
  - `OwnAudioSharp.Contract.csproj` — `PackageReference` on `OwnAudioSharp
    4.0.6`; a post-build `StageOwnAudioLibs` target stages the managed Ownaudio
    libs plus the platform-correct native FFI
    (`ownaudio_ffi.dll` / `libownaudio_ffi.so` / `libownaudio_ffi.dylib`) and
    the Ownaudio MIDI libs into the bridge output (the packages do not copy
    them by default).
  - `OwnAudioBridge.cs` — `[ClassBinding("OwnAudio")]` (lifecycle + config),
    `[ClassBinding("FileSource")]` and `[ClassBinding("AudioMixer")]` (factory +
    opaque-handle ops). The platform native lib is pre-loaded from the bridge
    folder on module init; OwnaudioNET owns its own resolver, so no
    `SetDllImportResolver` is registered here.
  - `ChipSynthBridge.cs` — `[ClassBinding("Chip")]` `ChipSynth`: pure helpers
    (`MidiFreq`, `NoteName`, `WaveName`, `Oscillate`, `Quantize`, `ClampVol`),
    low-level renderers (`RenderVoice`, `RenderChord` → unmanaged `ChipBuffer`),
    buffer accessors (`BufferAddress`/`BufferLength`/`FreeBuffer`), the streamer
    (`SpawnStream`), and fire-and-forget players (`PlaySilence`, `PlayTone`,
    `PlayNote`, `PlayNoteDuty`, `PlayNoteCrush`, `PlayChord`, `PlayMelody`,
    `PlaySlide`, `PlayMidiFile`).
- `../OwnAudioSharp.Contract/src/OwnAudio.ct` — the reusable `<ShadowBinding>`
  library surface (`import OwnAudioSharp;`).
- `../OwnAudioSharp.Contract/src/Chip.ct` — the `<ShadowBinding>` forwarders for
  `Chip` + the `Wave` enum.
- `src/main.ct` — demo entry point (imports the library, drives Chip).
- `src/diag.ct` — offline oscillator diagnostics (no audio device needed;
  not part of the build).
- `assets/song.mid` — sample MIDI file played by the demo.
- `assets/tone.wav` — 1s 440 Hz stereo 48 kHz WAV (retained for reference).