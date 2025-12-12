# Gamification System Implementation

## Overview

This document describes the complete gamification system implemented for ShivaayMusic. The system tracks user engagement through XP (experience points), levels, badges, daily quests, and rewards to enhance user retention and engagement.

## Architecture

### Database Layer

Five new entities have been added to the Room database (version 21):

1. **UserStatsEntity** - Tracks cumulative user statistics
   - Total listening time (milliseconds)
   - Unique artists discovered
   - Songs liked count
   - Playlists created count
   - Days active
   - Genres discovered

2. **UserLevelEntity** - Manages user level and XP
   - Current level
   - Current XP
   - XP needed for next level
   - Last level-up timestamp

3. **UserAchievementEntity** - Stores unlocked badges
   - User ID + Badge key (composite primary key)
   - Unlock timestamp

4. **UserRewardEntity** - Tracks unlocked rewards
   - User ID + Reward key (composite primary key)
   - Level at which reward was unlocked
   - Unlock timestamp

5. **DailyQuestEntity** - Manages daily quest progress
   - Quest key
   - Quest date
   - Progress value
   - Target value
   - XP reward
   - Completion status

### Core Logic

#### Level Progression

The level system uses a scalable formula: `XP_needed = 100 * level^1.4`

This creates:
- **Levels 1-10**: Fast progression (encourages early engagement)
- **Levels 10-20**: Moderate progression
- **Levels 20-50**: Slower long-term grind

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/utils/gamification/LevelCalculator.kt`

#### XP System

Users earn XP from various activities:

| Activity | XP Reward |
|----------|-----------|
| Listening to music | +10 XP per hour |
| Discovering unique artist | +20 XP |
| Liking a song | +5 XP |
| Creating a playlist | +30 XP |
| Being active for a day | +15 XP |
| Discovering new genre | +25 XP |
| Sharing content | +40 XP |
| Trying new feature | +50 XP (once) |

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/utils/gamification/XpCalculator.kt`

#### Anti-Cheat System

Prevents XP abuse through:
- Minimum 20-second play duration requirement
- 1-minute cooldown between repeated plays of same song
- Maximum 3 playlists created per minute
- Automatic cleanup of old tracking data

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/utils/gamification/AntiCheatValidator.kt`

#### Badges System

Seven starter badges available:

| Badge | Icon | Unlock Condition |
|-------|------|------------------|
| 1 Hour Listener | 🎧 | Listen for 1 hour total |
| 10 Hour Streak | 🔥 | Listen for 10 hours total |
| 100 Likes Club | 💙 | Like 100 songs |
| Playlist Maker | 🧩 | Create 5 playlists |
| Genre Explorer | 🌎 | Discover 10 genres |
| Night Owl | 🕒 | Listen at 2 AM (5 times) |
| Weekly Warrior | 🚀 | Maintain 7-day streak |

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/models/Badge.kt`

#### Rewards System

Level-based unlockables:

| Level | Rewards |
|-------|---------|
| 5 | Mini Gradient Theme, Custom Like Animation |
| 10 | Rare Profile Frame, New UI Accent |
| 15 | Glassmorphic Player Theme |
| 20 | VIP Badge |
| 30 | Hologram Animation |
| 40+ | Rare Profile Icons, Surprise Animation Pack |

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/models/Reward.kt`

#### Daily Quests

Three quests reset daily at midnight:

| Quest | Target | XP Reward |
|-------|--------|-----------|
| Music Time | Listen 20 minutes | +20 XP |
| Show Some Love | Like 5 songs | +10 XP |
| Music Discovery | Discover 1 new artist | +20 XP |

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/models/DailyQuest.kt`

### Integration Points

#### MusicService Integration

The gamification system integrates with `MusicService` at two key points:

1. **Playback Tracking** (`onPlaybackStatsReady`)
   - Tracks listening duration
   - Awards XP for time spent listening
   - Updates "Music Time" daily quest

2. **Like Tracking** (`toggleLike`)
   - Awards XP when user likes a song
   - Updates "Show Some Love" daily quest

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/playback/MusicService.kt`

#### GamificationEngine

The central orchestrator that:
- Initializes gamification data
- Calculates and awards XP
- Checks for level-ups
- Unlocks badges and rewards
- Manages daily quests
- Validates actions against anti-cheat rules

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/utils/gamification/GamificationEngine.kt`

#### GamificationIntegration

A lightweight wrapper that:
- Provides simple hooks for lifecycle events
- Checks if gamification is enabled via preferences
- Handles errors gracefully without disrupting music playback
- Runs operations on background thread

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/utils/gamification/GamificationIntegration.kt`

### UI Components

#### UserProfileScreen

Main gamification screen showing:
- **Header**: Level badge, username, XP progress bar
- **Daily Quests**: 3 cards showing progress
- **Achievements Grid**: 3x3 grid of badges (locked/unlocked)
- **Next Reward Card**: Shows upcoming unlock
- **Stats Card**: Displays all user statistics

Navigation route: `"profile"`

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/ui/screens/profile/UserProfileScreen.kt`

#### GamificationSettings

Settings screen for:
- Enable/disable gamification
- Show/hide level badge
- Toggle haptic feedback
- Toggle share reminders
- Info card explaining XP system

Navigation route: `"settings/gamification"`

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/ui/screens/settings/GamificationSettings.kt`

### ViewModel

**GamificationViewModel**

Provides reactive state flows for:
- User stats
- User level and progress
- Unlocked badges
- Unlocked rewards
- Daily quests
- Next reward to unlock
- All badges with lock status

Uses Hilt dependency injection for database and engine.

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/viewmodels/GamificationViewModel.kt`

## Settings & Preferences

Four new preference keys added:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| gamificationEnabled | Boolean | true | Master toggle for gamification |
| showLevelBadge | Boolean | true | Show level badge on profile |
| gamificationHaptics | Boolean | true | Vibrate on level-ups |
| shareReminders | Boolean | false | Suggest sharing milestones |

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/constants/PreferenceKeys.kt`

## Navigation

Two new routes added:

1. **Profile Screen**: `"profile"`
   - Accessible from: Settings > Gamification > View Your Profile
   
2. **Gamification Settings**: `"settings/gamification"`
   - Accessible from: Settings > Gamification

Implementation: `app/src/main/java/com/shivaay20005/shivaaymusic/ui/screens/NavigationBuilder.kt`

## Testing Recommendations

### Unit Tests
- Test XP calculation formulas
- Test level progression calculations
- Test anti-cheat validations
- Test badge unlock conditions
- Test daily quest logic

### Integration Tests
- Test database migrations
- Test DAO operations
- Test GamificationEngine workflows
- Test quest reset at midnight

### UI Tests
- Test profile screen displays correctly
- Test settings toggles work
- Test navigation flows
- Test progress bars animate correctly

### Manual Testing
1. **XP Tracking**:
   - Listen to music for 1 hour, verify +10 XP
   - Like 5 songs, verify +25 XP
   - Create playlist, verify +30 XP

2. **Level Progression**:
   - Start at level 1 with 0 XP
   - Earn 100 XP, verify level up to 2
   - Check XP progress bar accuracy

3. **Badges**:
   - Complete conditions for each badge
   - Verify unlock notifications
   - Verify badges appear in profile grid

4. **Daily Quests**:
   - Complete all 3 quests
   - Wait for midnight, verify reset
   - Verify XP awarded on completion

5. **Anti-Cheat**:
   - Try to spam song plays quickly
   - Try to create multiple playlists rapidly
   - Verify XP is not awarded for abuse

## Future Enhancements

### High Priority
- Level-up animation with confetti and haptic feedback
- Toast notifications for XP earned and badges unlocked
- Profile button in main navigation bar

### Medium Priority
- Artist-specific badges ("Fan of X" after N hours)
- Weekly challenges with higher XP rewards
- Leaderboard (optional, privacy-conscious)

### Low Priority
- Share card generator for social media
- Seasonal/limited-time badges
- Custom profile themes as rewards
- Achievement categories (Bronze/Silver/Gold)

## Troubleshooting

### XP Not Tracking
- Check if gamification is enabled in settings
- Verify database migration ran successfully
- Check logcat for exceptions in GamificationEngine

### Level Not Updating
- Verify XP is being added to database
- Check LevelCalculator formula is correct
- Ensure UI is observing Flow correctly

### Daily Quests Not Resetting
- Check system time is correct
- Verify DailyQuestManager reset logic
- Check database for old quest entries

### Performance Issues
- Ensure background operations use IO dispatcher
- Verify no database operations on main thread
- Check for memory leaks in ViewModels

## Database Migration

Version 20 → 21 adds:
- 5 new tables (user_stats, user_level, user_achievements, user_rewards, daily_quests)
- LocalDate type converter in Converters.kt
- New DAO methods for gamification

Migration is automatic via Room AutoMigration.

## Code Structure

```
app/src/main/java/com/shivaay20005/shivaaymusic/
├── db/
│   ├── entities/
│   │   ├── UserStatsEntity.kt
│   │   ├── UserLevelEntity.kt
│   │   ├── UserAchievementEntity.kt
│   │   ├── UserRewardEntity.kt
│   │   └── DailyQuestEntity.kt
│   ├── DatabaseDao.kt (gamification methods added)
│   ├── MusicDatabase.kt (entities added, version bumped)
│   └── Converters.kt (LocalDate converters added)
├── models/
│   ├── Badge.kt
│   ├── Reward.kt
│   └── DailyQuest.kt
├── utils/gamification/
│   ├── LevelCalculator.kt
│   ├── XpCalculator.kt
│   ├── AntiCheatValidator.kt
│   ├── AchievementManager.kt
│   ├── RewardManager.kt
│   ├── DailyQuestManager.kt
│   ├── GamificationEngine.kt
│   └── GamificationIntegration.kt
├── viewmodels/
│   └── GamificationViewModel.kt
├── ui/screens/
│   ├── profile/
│   │   └── UserProfileScreen.kt
│   └── settings/
│       └── GamificationSettings.kt
├── constants/
│   └── PreferenceKeys.kt (gamification keys added)
└── playback/
    └── MusicService.kt (integration hooks added)
```

## Contributors

This gamification system was implemented to enhance user engagement and retention in ShivaayMusic through game-like progression mechanics while maintaining focus on music listening experience.

---

For questions or issues, please refer to the main README or open an issue on GitHub.
