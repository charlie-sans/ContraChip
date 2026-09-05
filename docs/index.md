# ContraChip

*Version: 0.1.0*

A Contract application (audio demo)

---

## Table of Contents

- **contrachip**
  - [Chip](#chip)
  - [Program](#program)
  - [Program](#program)
  - [Wave](#wave)

---

## contrachip

### Chip

**contract**

```contract
Contract Chip
```

#### ClampVol

**function**

```contract
static fn ClampVol(v: float) -> float
```

Clamp a volume value to 0.0..1.0.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `v` | `float` | Volume input. |

**Returns:** `float` -- Clamped value in 0.0..1.0.

---

#### MidiFreq

**function**

```contract
static fn MidiFreq(midi: int) -> float
```

Convert a MIDI note number to frequency in Hz.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `midi` | `int` | MIDI note number (21..108 covers piano range). |

**Returns:** `float` -- Frequency in Hz.

**Remarks:** A4 (69) = 440 Hz. Uses equal temperament with iterative ratio multiply.

---

#### NoteName

**function**

```contract
static fn NoteName(midi: int) -> string
```

Return the note name for a MIDI number.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `midi` | `int` | MIDI note number. |

**Returns:** `string` -- Note name with octave, e.g. "C4", "F#5".

**Remarks:** e.g. 60 => "C4", 72 => "C5", 69 => "A4". Sharps for black keys.

---

#### Oscillate

**function**

```contract
static fn Oscillate(wave: int, phase: float, duty: float) -> float
```

Generate one sample from a waveform at a given phase.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `wave` | `int` | Waveform type. |
| `phase` | `float` | Phase position 0.0..1.0 within one cycle. |
| `duty` | `float` | Duty cycle for Pulse (0.05..0.95). Ignored for other waves. |

**Returns:** `float` -- Amplitude sample in -1.0..+1.0.

**Remarks:** Phase is 0.0..1.0 (one full cycle). Duty only affects Pulse/Square.
Returns a value in -1.0..+1.0 (Noise returns -1..+1 randomly).

---

#### PlayChord

**function**

```contract
static fn PlayChord(notes: int[], wave: int, seconds: float, volume: float)
```

Play a chord (multiple MIDI notes simultaneously).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `notes` | `int[]` | Array of MIDI note numbers (e.g. [60, 64, 67] for C major). |
| `wave` | `int` | Waveform type for all voices. |
| `seconds` | `float` | Duration in seconds. |
| `volume` | `float` | Amplitude 0.0..1.0 (shared across voices). |

**Remarks:** All notes use the same waveform and volume. Voices are averaged
(not summed) so the output stays in -1..+1 regardless of note count.

**Example:**

```contract
var c: int[] = [60, 64, 67];
Chip.PlayChord(c, Wave.Square, 0.8, 0.4);

var f: int[] = [53, 57, 60];
Chip.PlayChord(f, Wave.Saw, 0.5, 0.3);
```

---

#### PlayMelody

**function**

```contract
static fn PlayMelody(notes: int[], noteLen: float, wave: int, volume: float, gap: float)
```

Play a melody: a sequence of MIDI notes with consistent timing.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `notes` | `int[]` | Array of MIDI note numbers to play in order. |
| `noteLen` | `float` | Duration of each note in seconds (e.g. 0.12 for 120ms). |
| `wave` | `int` | Waveform type. |
| `volume` | `float` | Amplitude 0.0..1.0. |
| `gap` | `float` | Silence between notes in seconds (e.g. 0.02 for 20ms). |

**Remarks:** Pre-renders the entire sequence (notes + inter-note gaps) into one
contiguous buffer, then streams it via a single thread. Notes do not
overlap — each note plays for noteLen seconds, followed by gap seconds
of silence.

**Example:**

```contract
var scale: int[] = [60, 62, 64, 65, 67, 69, 71, 72];
Chip.PlayMelody(scale, 0.12, Wave.Pulse, 0.5, 0.02);

var riff: int[] = [67, 65, 64, 60];
Chip.PlayMelody(riff, 0.2, Wave.Square, 0.4, 0.05);
```

---

#### PlayNote

**function**

```contract
static fn PlayNote(midi: int, wave: int, seconds: float, volume: float)
```

Play a MIDI note with 50% duty cycle.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `midi` | `int` | MIDI note number (e.g. 60 = C4, 69 = A4). |
| `wave` | `int` | Waveform type. |
| `seconds` | `float` | Duration in seconds. |
| `volume` | `float` | Amplitude 0.0..1.0. |

**Remarks:** Convenience wrapper around PlayNoteDuty with duty=0.5.
Fire-and-forget: pre-renders and streams in background.

**Example:**

```contract
Chip.PlayNote(69, Wave.Square, 0.4, 0.5);
Chip.PlayNote(60, Wave.Sine, 1.0, 0.3);
```

---

#### PlayNoteCrush

**function**

```contract
static fn PlayNoteCrush(midi: int, wave: int, seconds: float, volume: float, duty: float, crush: int)
```

Play a MIDI note with bit-crush effect.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `midi` | `int` | MIDI note number. |
| `wave` | `int` | Waveform type. |
| `seconds` | `float` | Duration in seconds. |
| `volume` | `float` | Amplitude 0.0..1.0. |
| `duty` | `float` | Duty cycle for Pulse wave. |
| `crush` | `int` | Number of amplitude levels (4..256). |

**Remarks:** Crush reduces the number of amplitude levels. Lower crush = more
lo-fi. Typical values: 4 (very crushed), 8 (retro), 16 (mild), 256 (near-clean).

**Example:**

```contract
Chip.PlayNoteCrush(76, Wave.Saw, 0.4, 0.45, 0.5, 16);
```

---

#### PlayNoteDuty

**function**

```contract
static fn PlayNoteDuty(midi: int, wave: int, seconds: float, volume: float, duty: float)
```

Play a MIDI note with a custom duty cycle.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `midi` | `int` | MIDI note number. |
| `wave` | `int` | Waveform type. |
| `seconds` | `float` | Duration in seconds. |
| `volume` | `float` | Amplitude 0.0..1.0. |
| `duty` | `float` | Duty cycle (0.05..0.95). |

**Remarks:** Ideal for Pulse wave. Low duty (0.1) = thin, nasal.
High duty (0.9) = fat, hollow. 0.5 = same as Square.

**Example:**

```contract
Chip.PlayNoteDuty(64, Wave.Pulse, 0.3, 0.5, 0.25);
Chip.PlayNoteDuty(72, Wave.Pulse, 0.2, 0.4, 0.1);
```

---

#### PlaySilence

**function**

```contract
static fn PlaySilence(seconds: float)
```

Play silence for a given duration.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `seconds` | `float` | Duration in seconds. |

**Remarks:** Useful as a spacer between sounds. Pre-renders a zero-amplitude
buffer and streams it in the background.

---

#### PlaySlide

**function**

```contract
static fn PlaySlide(fromMidi: int, toMidi: int, wave: int, seconds: float, volume: float)
```

Play a frequency slide (glissando) between two MIDI notes.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fromMidi` | `int` | Starting MIDI note number. |
| `toMidi` | `int` | Ending MIDI note number. |
| `wave` | `int` | Waveform type. |
| `seconds` | `float` | Duration of the slide in seconds. |
| `volume` | `float` | Amplitude 0.0..1.0. |

**Remarks:** Sweeps linearly from fromMidi's frequency to toMidi's frequency
over the given duration. Great for laser zaps, coin sounds, risers.

**Example:**

```contract
Chip.PlaySlide(80, 40, Wave.Saw, 0.3, 0.35);   // laser zap down
Chip.PlaySlide(60, 96, Wave.Square, 0.2, 0.3);  // coin slide up
```

---

#### PlayTone

**function**

```contract
static fn PlayTone(freq: float, wave: int, seconds: float, volume: float, duty: float)
```

Play a tone at a specific frequency.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `freq` | `float` | Frequency in Hz (e.g. 440.0 for A4). |
| `wave` | `int` | Waveform type. |
| `seconds` | `float` | Duration in seconds. |
| `volume` | `float` | Amplitude 0.0..1.0. |
| `duty` | `float` | Duty cycle for Pulse wave (0.05..0.95). |

**Remarks:** Fire-and-forget: pre-renders and streams in background.

**Example:**

```contract
Chip.PlayTone(440.0, Wave.Saw, 0.5, 0.4, 0.5);
Chip.PlayTone(261.63, Wave.Triangle, 1.0, 0.3, 0.5);
```

---

#### Quantize

**function**

```contract
static fn Quantize(s: float, steps: int) -> float
```

Quantize a float to a given number of discrete steps.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `float` | Input sample value. |
| `steps` | `int` | Number of discrete levels (e.g. 8, 16, 256). 0 or less = no quantization. |

**Returns:** `float` -- Quantized value.

**Remarks:** Useful for bit-crush effects. Steps=256 is near-clean, steps=4 is very crushed.

---

#### RenderChord

**function**

```contract
static fn RenderChord(notes: int[], wave: int, total: int, volume: float, duty: float) -> ManagedPtr<float>
```

Render a full buffer for a chord (multiple voices averaged).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `notes` | `int[]` | Array of MIDI note numbers to play simultaneously. |
| `wave` | `int` | Waveform type for all voices. |
| `total` | `int` | Number of frames (samples per channel). |
| `volume` | `float` | Amplitude 0.0..1.0 (shared across voices). |
| `duty` | `float` | Duty cycle for Pulse wave. |

**Returns:** `ManagedPtr<float>` -- ManagedPtr containing interleaved stereo float samples.

**Remarks:** Each note is rendered independently and mixed at equal volume.
Apply fade-in/out (5ms) to avoid clicks.

---

#### RenderVoice

**function**

```contract
static fn RenderVoice(freq: float, wave: int, total: int, volume: float, duty: float, freqEnd: float, crush: float, sweep: bool) -> ManagedPtr<float>
```

Render a full buffer of interleaved stereo samples for one voice.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `freq` | `float` | Base frequency in Hz. |
| `wave` | `int` | Waveform type. |
| `total` | `int` | Number of frames (samples per channel). |
| `volume` | `float` | Amplitude 0.0..1.0. |
| `duty` | `float` | Duty cycle for Pulse wave. |
| `freqEnd` | `float` | End frequency for sweep (ignored if sweep=false). |
| `crush` | `float` | Bit-crush steps (0 = off, 4 = heavy, 256 = near-clean). |
| `sweep` | `bool` | Enable frequency sweep from freq to freqEnd. |

**Returns:** `ManagedPtr<float>` -- ManagedPtr containing interleaved stereo float samples.

**Remarks:** Called internally by Play* functions. Pure math — runs as fast as the
interpreter can go. Apply fade-in/out (5ms), volume envelope, and optional
frequency sweep + bit crush.

---

#### SpawnStream

**function**

```contract
static fn SpawnStream(buf: ManagedPtr<float>, totalSamples: int)
```

Spawn a background thread that streams a pre-rendered buffer to the output ring.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `buf` | `ManagedPtr<float>` | Pre-rendered interleaved stereo buffer. |
| `totalSamples` | `int` | Total float samples in the buffer (frames * channels). |

**Remarks:** Uses pointer arithmetic to send chunks directly from the pre-rendered
buffer (no temp copy). The thread frees the buffer when done.
The calling thread returns immediately.

---

#### WaveName

**function**

```contract
static fn WaveName(wave: int) -> string
```

Return a human-readable name for a Wave enum value.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `wave` | `int` | Wave enum value (Wave.Sine, Wave.Square, etc.). |

**Returns:** `string` -- String like "Sine", "Square", "Saw", etc.

---

---

### Program

**contract**

```contract
Contract Program
```

#### Main

**function**

```contract
static fn Main()
```

---

#### Stats

**function**

```contract
static fn Stats(wave: int, midi: int, duty: float)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `wave` | `int` |  |
| `midi` | `int` |  |
| `duty` | `float` |  |

---

---

### Program

**contract**

```contract
Contract Program
```

#### Main

**function**

```contract
static fn Main()
```

---

#### PlayChords

**function**

```contract
static fn PlayChords()
```

---

#### PlayEffects

**function**

```contract
static fn PlayEffects()
```

---

#### PlayScale

**function**

```contract
static fn PlayScale()
```

---

#### ShowTheory

**function**

```contract
static fn ShowTheory()
```

---

#### TourWaves

**function**

```contract
static fn TourWaves()
```

---

---

### Wave

**enum**

```contract
enum Wave { Sine, Square, Saw, Triangle, Noise, Pulse }
```

A tiny 16-bit-era chiptune synth over the OwnAudio engine.

**Remarks:** All rendering is fully pre-computed: each Play* call fills a
ManagedPtr buffer offline, then streams it to the output ring via
a background thread. The calling thread returns immediately.

Waveforms: Sine, Square, Saw, Triangle, Noise, Pulse.
Pulse takes a duty cycle (0.05..0.95); Square is Pulse at 0.5.

Threads spawned by Play* calls free their own buffers when done.
Multiple voices can overlap naturally — the output ring mixes them.

**Example:**

```contract
Chip.PlayNote(69, Wave.Square, 0.4, 0.5);
Chip.PlayNoteDuty(64, Wave.Pulse, 0.3, 0.5, 0.25);
Chip.PlayTone(440.0, Wave.Saw, 0.5, 0.4, 0.5);

var chord: int[] = [60, 64, 67];
Chip.PlayChord(chord, Wave.Square, 0.8, 0.4);

var scale: int[] = [60, 62, 64, 65, 67, 69, 71, 72];
Chip.PlayMelody(scale, 0.12, Wave.Pulse, 0.5, 0.02);

Chip.PlaySlide(40, 80, Wave.Saw, 0.5, 0.4);
```

---

