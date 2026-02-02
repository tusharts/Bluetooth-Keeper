# Bluetooth Keeper 🔊🔋

**Bluetooth Keeper** is a specialized utility application designed to solve a common annoyance with modern Bluetooth speakers: the auto-shutoff feature. Many speakers turn themselves off after a few minutes of silence to save battery, forcing you to constantly reconnect them. 

Bluetooth Keeper runs intelligently in the background, periodically playing a virtually silent audio "ping" to trick the speaker into staying awake, without interrupting your workflow or media consumption.

## 📥 Download

You can download the latest APK directly from the **[GitHub Releases Page](https://github.com/tusharts/Bluetooth-Keeper/releases)**.

---

## 🚀 Features

- **Smart "Keep-Alive" Algorithm**: Automatically detects silence and plays a micro-sound to reset the speaker's idle timer.
- **Intelligent Monitoring**:
  - **Connection Aware**: Only runs when a Bluetooth device is connected (configurable).
  - **Media Aware**: Detects if music or other media is already playing and pauses its own operation to avoid interference.
- **Background Persistence**: Utilizes a robust foreground service to ensure the app continues working even when minimized or the screen is locked.
- **Non-Intrusive**: Uses audio mixing configurations (mixWithOthers) to ensure the "ping" never pauses your Spotify, YouTube, or calls.
- **Battery Efficient**: Optimizes sleep cycles and only wakes up when absolutely necessary.

## 🛠 Tech Stack

This project demonstrates advanced Flutter capabilities, particularly in native platform integration and background process management.

*   **Framework**: Flutter (Dart)
*   **Architecture**: Modular design with custom local plugins.
*   **Key Libraries**:
    *   lutter_background_service: For managing persistent Android foreground services.
    *   udioplayers & udio_session: For precise audio playback control and managing audio focus.
    *   lutter_local_notifications: For required service notifications.
    *   shared_preferences: For persisting user configurations.
*   **Native Integration (Custom Plugin)**:
    *   Implemented a local plugin udio_helper using **Platform Channels** to access native Android APIs (checking AudioManager.isMusicActive() and Bluetooth connection state) which are not available in standard cross-platform packages.

## ⚙️ How It Works

The app employs a state machine running in a dedicated background isolate:

1.  **Check Connection**: Verifies if a Bluetooth device is connected (via custom Native API).
2.  **Check Activity**: Queries the OS to see if any other app is currently outputting audio.
3.  **Wait**: If the speaker is idle, it waits for a user-defined interval (default: 5 minutes).
4.  **Ping**: If no music has started during the wait, it plays a 1-byte silent WAV file. This signal is strong enough to keep the speaker hardware active but inaudible to the user.
5.  **Loop**: The cycle repeats, ensuring your device never disconnects unexpectedly.

## 👨‍💻 Author
---
*Note: This project is intended for personal utility and educational purposes regarding background services in modern Android versions.*
