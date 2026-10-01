# Clean explosion replacement

The project-wide compressed `Loud Explosion` MP3 reuse was retired after audible distortion was reported during repeated and pitch-shifted playback.

## Runtime sources now used
- Compact impact: Kenney Sci-Fi Sounds CC0 `explosionCrunch_000`, already tracked as `alchemist_failed_boom_cauldron.wav`.
- Heavy explosion/impact: Kenney Sci-Fi Sounds CC0 `explosionCrunch_001`, already tracked as `alchemist_failed_boom_skill3.wav`.

## Replaced runtime cues
- Stage 1 arcane piercer -> heavy WAV
- Stage 3 shield charge impact -> heavy WAV
- Stage 4 pistol shot -> compact WAV
- Stage 4 cylinder strike -> compact WAV
- Stage 4 Deadeye shot -> compact WAV
- Stage 5 combustion release -> heavy WAV
- Stage 5 earth spike -> compact WAV
- Stage 6 ground slam -> heavy WAV
- Stage 10 Black Spot Explosion -> heavy WAV

The obsolete Stage 5 ice-impact MP3 was also removed; Ice Bolt already uses its dedicated glass/crystal WAV pair.

## Pixabay comparison
For a possible later source refresh, `Explosion Sound Effect` by DRAGON-STUDIO (3s) and `Hard Heavy Impact` were checked on Pixabay and marked free for use under the Pixabay Content License. Their direct MP3 bytes were not available through the connector, so this commit does not claim to include them.
