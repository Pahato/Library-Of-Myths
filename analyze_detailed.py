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
    diff_ms = (beat_times[i] - i * 60/130) * 1000
    print(f'  Beat {i}: detected={beat_times[i]:.3f}s, expected={i*60/130:.3f}s, diff={detected - i*60/130:.3f}s ({diff*1000:.1f}ms)')

print()

# Check phase drift over time
print("Phase drift at key timestamps:")
for t in [10, 20, 30, 40, 50, 60, 70]:
    idx = np.argmin(np.abs(librosa.frames_to_time(librosa.beat.beat_track(librosa.load(r'C:\Users\rodri\Downloads\Kaal Sankat.mp3')[0], sr=48000)[1], sr=48000) - t))
    print(f'  At {t}s: nearest beat at {librosa.frames_to_time(librosa.beat.beat_track(librosa.load(r"C:\Users\rodri\Downloads\Kaal Sankat.mp3")[0], sr=22050)[1], sr=22050)[np.argmin(np.abs(librosa.frames_to_time(librosa.beat.beat_track(librosa.load(r"C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap\assets\music\orbital_colossus.wav")[0], sr=22050)[1], sr=22050) - t))]:.3f}s')