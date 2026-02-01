# Bluetooth Keeper

Bluetooth Keeper is a Flutter application designed to prevent Bluetooth speakers from falling asleep or disconnecting due to inactivity. It works by playing a very short, silent audio "ping" at regular intervals, ensuring the audio channel remains active without disturbing the user.

## 🚀 Features

*   **Background Service:** Runs continuously in the background, even when the app is closed.
*   **Smart Detection:**
    *   **Activity Check:** Only pings if no other media (music, video) is currently playing.
    *   **Bluetooth Check:** Optionally runs only when a Bluetooth audio device (A2DP) is connected.
*   **Configurable Interval:** Adjust the silence interval from 1 to 20 minutes to suit your specific speaker's timeout settings.
*   **Silent Operation:** The "ping" is a silent audio file, so it keeps the connection alive without making noise.
*   **Android 14 Ready:** Complies with modern Android foreground service requirements.

## 📱 Screenshots

| Home Screen | Settings |
|:---:|:---:|
| *(Add your screenshot here)* | *(Add your screenshot here)* |

## 🛠️ Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/bluetooth-keeper.git
    cd bluetooth-keeper
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the App:**
    ```bash
    flutter run
    ```

## ⚙️ Configuration

### Android Permissions
The app requires the following permissions to function correctly:
*   `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_MEDIA_PLAYBACK`: To run in the background.
*   `BLUETOOTH_CONNECT`: To detect if a Bluetooth device is connected (Android 12+).
*   `POST_NOTIFICATIONS`: To show the persistent service notification (Android 13+).

### Battery Optimization
**Important:** For the app to work reliably in the background for long periods, users should disable **Battery Optimization** for this app in their Android system settings.

## 🧩 Project Structure

*   `lib/`
    *   `main.dart`: Contains the UI and the background service logic.
    *   `silent_data.dart`: Contains the base64 encoded string of the silent audio file.
*   `local_plugins/audio_helper`: A custom native Android plugin used to:
    *   Check if music is currently active (`AudioManager.isMusicActive`).
    *   Check for connected Bluetooth devices.
*   `android/`: Native Android configuration (Kotlin).

## 🏗️ Building for Release

To build an APK for Android:

```bash
flutter build apk --release
```

The output will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## 📄 License

This project is open source and available under the MIT License.
