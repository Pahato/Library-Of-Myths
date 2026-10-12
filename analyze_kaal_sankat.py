import os
os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')
import librosa
import numpy as np

y, sr = librosa.load(r'C:\Users\rodri\Downloads\Kaal Sankat.mp3', sr=None)
tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
beat_times = librosa.frames_to_time(beat_frames, sr=sr)

print('=== KAAL SANKAT ANALYSIS ===')
print(f'Duration: {len(y)/sr:.2f} seconds ({len(y)/sr/60:.2f} minutes)')
print(f'Estimated tempo: {tempo[0] if hasattr(tempo, "__len__") else tempo:.2f} BPM')
print(f'Number of beats: {len(beat_frames)}')
print()

# Compare with game's 130 BPM
game_bpm = 130.0
estimated_bpm = tempo[0] if hasattr(tempo, '__len__') else tempo
print(f'Game BPM: {game_bpm}')
print(f'Estimated BPM: {estimated_bpm:.2f}')
print(f'Difference: {abs(estimated_bpm - game_bpm):.2f} BPM')
print()

# Check beat alignment with game's beat grid
beat_times = librosa.frames_to_time(librosa.beat.beat_track(y=y, sr=sr)[1], sr=sr)
game_beat_times = np.arange(0, 80, 60/130)
print('First 10 detected beats:', beat_times[:10])
print('First 10 game beats:', game_beat_times[:10])
print()

# Check alignment at key timestamps
key_times = [3.5, 22.0, 42.0, 60.0, 72.0]
for kt in key_times:
    idx = np.argmin(np.abs(beat_times - kt))
    diff = beat_times[idx] - kt
    print(f'Chart boundary {kt}s: nearest beat at {beat_times[idx]:.3f}s (diff: {diff*1000:.1f}ms)')