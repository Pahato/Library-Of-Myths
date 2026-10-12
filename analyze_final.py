import librosa
import numpy as np

print("=== KAAL SANKAT DETAILED ANALYSIS ===")

y, sr = librosa.load(r'C:\Users\rodri\Downloads\Kaal Sankat.mp3', sr=None)
tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
beat_times = librosa.frames_to_time(beat_frames, sr=sr)

print(f'Duration: {len(y)/sr:.2f} seconds ({len(y)/sr/60:.2f} minutes)')
print(f'Estimated tempo: {tempo[0] if hasattr(tempo, "__len__") else tempo:.2f} BPM')
print(f'Number of beats: {len(beat_frames)}')
print()

# Compare with game's 130 BPM
game_bpm = 130.0
game_beat_time = 60.0 / 130.0
estimated_bpm = tempo[0] if hasattr(tempo, "__len__") else tempo
print(f'Game BPM: {game_bpm}')
print(f'Estimated BPM: {tempo[0] if hasattr(tempo, "__len__") else tempo:.2f}')
print(f'Difference: {abs(tempo[0] if hasattr(tempo, "__len__") else tempo - 130.0):.2f} BPM')
print()

# Check beat alignment with game's beat grid
beat_times = librosa.frames_to_time(librosa.beat.beat_track(y=y, sr=sr)[1], sr=sr)
game_beat_times = np.arange(0, 80, 60/130)

print('First 10 detected beats vs game grid:')
for i in range(min(10, len(beat_frames))):
    game_time = i * 60/130
    detected = beat_times[i]
    diff = detected - i * 60/130
    print(f'  Beat {i}: detected={detected:.3f}s, expected={game_time:.3f}s, diff={diff*1000:.1f}ms')

print()

# Check alignment at chart boundaries
chart_boundaries = [3.5, 22.0, 42.0, 60.0, 72.0]
beat_times = librosa.frames_to_time(librosa.beat.beat_track(y=y, sr=sr)[1], sr=sr)

print("Beat alignment at chart boundaries:")
for boundary in [3.5, 22.0, 42.0, 60.0, 72.0]:
    idx = np.argmin(np.abs(beat_times - boundary))
    diff = beat_times[idx] - boundary
    print(f'  Chart boundary {boundary}s: nearest beat at {beat_times[idx]:.3f}s (diff: {diff*1000:.1f}ms)')