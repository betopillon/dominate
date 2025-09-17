# Dominate Game - Development Guidelines

## Project Overview
Dominate is a mobile strategy game built with Flutter Flame for cross-platform deployment.

## 🎯 Game Rules - Dominate

### Core Objective
**Goal:** Occupy the maximum number of blocks possible. The player with the most blocks when all blocks are occupied wins.

### Game Setup
- **Board:** 8x8 grid = 64 total blocks
- **Players:** 2-4 players supported
- **Colors:** Each player selects a unique color
- **Turn-based:** Players take turns placing their colored blocks

### Gameplay Mechanics
- Players take turns placing blocks on empty spaces
- Goal is to occupy as many blocks as possible
- Game ends when all 64 blocks are occupied
- Winner is determined by counting occupied blocks per player

## Fundamental Rules & Guidelines

### 🎮 Game Type & Platform
- **Mobile-first game** designed for touch interfaces
- **Target platforms:** Apple App Store and Google Play Store
- **Game style:** Strategic block occupation game
- **Framework:** Flutter Flame for cross-platform development

### 🌐 Multiplayer Considerations
- **Current:** Single-player/local multiplayer implementation
- **Future:** Full multiplayer support planned
- **Architecture:** Design with multiplayer scalability in mind
- **Networking:** Prepare code structure for future online play integration

### 📱 Mobile Optimization Requirements
- **Touch-friendly UI:** Large, responsive touch targets
- **Performance:** Smooth 60fps gameplay on mobile devices
- **Screen sizes:** Support various mobile screen resolutions
- **Orientation:** Consider portrait and landscape modes
- **Battery efficiency:** Optimize for mobile battery life

### 🔄 Version Management
- **Semantic versioning:** Use MAJOR.MINOR.PATCH format
- **Version tracking:** Update version numbers with each significant change
- **Changelog:** Document all changes in commits
- **Release notes:** Prepare for app store submissions

### 📝 Development Commands
- **Run project:** `flutter run`
- **Build for release:** `flutter build apk` (Android) / `flutter build ios` (iOS)
- **Test:** `flutter test`
- **Lint:** `flutter analyze`

### 🎯 Current Development Focus
1. Core game mechanics (Othello-like gameplay)
2. Mobile-optimized UI/UX
3. Local multiplayer support
4. Game state management
5. Audio and visual effects

### 🔮 Future Roadmap
- Online multiplayer implementation
- User accounts and profiles
- Leaderboards and achievements
- Social features
- In-app purchases (if applicable)

---
*Last updated: 2025-09-14*
*Current version: 1.0.0+1*