# ShivaayMusic Widget - Visual Structure

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                        [ShivaayMusic Logo] 🎵   ║
║  ┌──────────┐  ┌─────────────────────────────────┐  ┌──────────────────────┐ ║
║  │          │  │  Song Title (Bold, 14sp)        │  │  🔀  ⏮  ⏯  ⏭  ❤   │ ║
║  │  Album   │  │  Artist Name (12sp)             │  │                      │ ║
║  │  Art     │  │  ─────────────────── [Progress] │  │  Shuffle  Prev      │ ║
║  │  64x64   │  │  0:00              3:45         │  │  Play  Next  Like   │ ║
║  │          │  │                                  │  │                      │ ║
║  └──────────┘  └─────────────────────────────────┘  └──────────────────────┘ ║
║                                                                                 ║
║  Tap album → Opens app                   Tap controls → Control playback      ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

## Widget Layout Components

### Left Section: Album Art
- **Size**: 64dp x 64dp
- **Shape**: Rounded corners
- **Function**: Displays current song artwork, tap to open app
- **Fallback**: Music note icon if no artwork available

### Center Section: Song Information & Progress
1. **Song Title**
   - Bold, 14sp text
   - Marquee scrolling for long titles
   - Updates on song change

2. **Artist Name**
   - Regular, 12sp text
   - 80% opacity for subtle look
   - Truncates if too long

3. **Progress Bar**
   - Horizontal bar, 4dp height
   - Light color tint
   - Updates every second

4. **Time Labels**
   - Left: Current position (e.g., "1:23")
   - Right: Total duration (e.g., "3:45")
   - Small text, 10sp, 70% opacity

### Right Section: Playback Controls
- **Shuffle** (32dp): Toggle shuffle mode
- **Previous** (36dp): Skip to previous track
- **Play/Pause** (44dp): Toggle playback (largest button)
- **Next** (36dp): Skip to next track
- **Like** (32dp): Toggle favorite status

### Top Right: Branding
- ShivaayMusic logo (20dp x 20dp)
- 80% opacity
- Always visible for brand recognition

## Widget States

### Playing State
```
╔═══════════════════════════════════════════════╗
║                              [Logo] 🎵         ║
║  [Album] Bohemian Rhapsody      🔀 ⏮ ⏸ ⏭ ❤  ║
║   Art    Queen                                 ║
║          ████████────── 65%                    ║
║          2:30      3:52                        ║
╚═══════════════════════════════════════════════╝
```

### Idle State
```
╔═══════════════════════════════════════════════╗
║                              [Logo] 🎵         ║
║  [Music] No song playing        🔀 ⏮ ⏯ ⏭ ❤  ║
║   Note   Open ShivaayMusic to play            ║
║          ────────────── 0%                     ║
║          0:00      0:00                        ║
╚═══════════════════════════════════════════════╝
```

### Paused State
```
╔═══════════════════════════════════════════════╗
║                              [Logo] 🎵         ║
║  [Album] Imagine               🔀 ⏮ ⏯ ⏭ ❤  ║
║   Art    John Lennon                           ║
║          ███───────── 30%                      ║
║          0:55      3:03                        ║
╚═══════════════════════════════════════════════╝
```

## Design Features

### Glass Morphism Background
- Semi-transparent white (#25FFFFFF)
- Gradient overlay for depth
- 1dp white border (#30FFFFFF)
- 18dp rounded corners
- Subtle shadow for elevation

### Color Scheme
- **Primary Text**: Light color (@color/Lights)
- **Secondary Text**: Light with 80% opacity
- **Progress Bar**: Light tint
- **Controls**: Light icons with ripple effect
- **Background**: Glass effect with blur

### Responsive Layout
- **Minimum Size**: 250dp x 110dp
- **Target Grid**: 4 cells wide × 2 cells tall
- **Resizable**: Both horizontal and vertical
- **Adapts**: Content scales within constraints

## User Interactions

| Element | Action | Result |
|---------|--------|--------|
| Album Art | Single Tap | Opens ShivaayMusic app |
| Play/Pause | Single Tap | Toggles playback state |
| Previous | Single Tap | Skips to previous track |
| Next | Single Tap | Skips to next track |
| Shuffle | Single Tap | Toggles shuffle mode |
| Like | Single Tap | Toggles favorite status |

## Update Behavior

- **Automatic Updates**: Every 1 second while enabled
- **Progress**: Updates continuously during playback
- **Song Info**: Updates immediately on track change
- **Controls**: Update to reflect current state
- **Album Art**: Loads asynchronously from URL

## Accessibility

- Content descriptions for all interactive elements
- Proper contrast ratios for text
- Touch targets meet minimum size guidelines (32dp+)
- Visual feedback on interactions (ripple effect)

## Performance

- Efficient updates (only when needed)
- Async image loading (doesn't block UI)
- Handler-based scheduling (prevents battery drain)
- Lightweight RemoteViews implementation

This widget provides a complete, beautiful, and functional music control interface that users can access directly from their home screen without opening the app.
