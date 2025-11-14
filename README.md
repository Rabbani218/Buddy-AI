
# HealthBuddy AI

HealthBuddy AI is an advanced, multi-platform AI chat assistant built with Flutter. Powered by Google Gemini, this application offers a seamless, responsive, and interactive conversational experience across multiple devices.

\<div align="center"\>
\<img src="[INSERT\_YOUR\_SCREENSHOT\_LINK\_HERE]" alt="HealthBuddy AI Screenshot" width="800"/\>
\</div\>

-----

## 🚀 Key Features

  * **Modern Glassmorphism UI:** A clean, aesthetic interface with a glassmorphism effect that adapts to system Light and Dark modes.
  * **3D AI Avatar:** An interactive AI avatar rendered in real-time from a `.glb` file (via `model_viewer_plus`).
  * **Streaming Responses:** AI responses appear word-by-word (typewriter effect), powered by Gemini's `streamGenerateContent`.
  * **Conversation Memory:** The AI can "remember" previous messages in the conversation to provide contextual responses.
  * **Full Voice Interaction:**
      * **Speech-to-Text (STT):** Input messages using your voice (supports multiple locales).
      * **Text-to-Speech (TTS):** Listen to the AI's responses in a supported language (defaults to Indonesian).
  * **Persistent Chat History:** All conversations are saved locally using the lightning-fast NoSQL database, **Isar**.
  * **Multi-Platform:** A single codebase that runs on **Windows**, **Android**, and the **Web**.
  * **Multi-Language (i18n):** Supports multiple languages for the UI (English, Indonesian, Japanese) using `flutter_gen_l10n`.
  * **Quick Actions:** Action buttons on AI chat bubbles to **Copy**, **Share**, or **Replay** the audio response.

## 🛠️ Tech Stack

  * **Framework:** Flutter
  * **State Management:** Riverpod
  * **AI Model:** Google Gemini (via `google_generative_ai`)
  * **Database:** Isar (Local, NoSQL)
  * **3D Rendering:** `model_viewer_plus`
  * **Icons & Assets:** `flutter_svg`
  * **Voice:** `flutter_tts` & `speech_to_text`
  * **UI:** `flutter_markdown` (for rendering responses)
  * **Internationalization:** `flutter_gen_l10n`

-----

## ⚙️ Getting Started

This project requires a few specific setup steps due to its reliance on code generators and external APIs.

### 1\. Prerequisites

  * [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.x or newer)
  * A Code Editor (VS Code, Android Studio, etc.)
  * (For Android) Android SDK
  * (For Windows) Visual Studio 2022 with "Desktop development with C++" workload

### 2\. Installation & Setup

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/[YOUR_USERNAME]/healthbuddy_ai.git
    cd healthbuddy_ai
    ```

2.  **Get a Gemini API Key:**

      * Create your API Key at [Google AI Studio](https://aistudio.google.com/app/apikey).
      * Create a new file at `lib/services/api_key.dart`.
      * Add your key to this file:
        ```dart
        // lib/services/api_key.dart
        const String geminiApiKey = 'YOUR_API_KEY_HERE';
        ```

    *(Note: This `api_key.dart` file is already in `.gitignore` to prevent leaking your key).*

3.  **Install Dependencies:**

    ```bash
    flutter pub get
    ```

4.  **Run Code Generators (VERY IMPORTANT):**
    This project uses `build_runner` for Isar and `flutter_gen_l10n` for languages. You **must** run these commands before launching the app:

    ```bash
    # To generate database files (.g.dart)
    flutter pub run build_runner build --delete-conflicting-outputs

    # To generate localization/language files
    flutter gen-l10n
    ```

### 3\. Running the Application

After all setup steps are complete, use the following commands to run the app:

**💻 For Windows:**

```bash
flutter run -d windows
```

**📱 For Android:**
(Ensure an emulator is running or a device is connected)

```bash
flutter run
```

**🌐 For Web (Development Mode):**
This specific command is required to bypass **CORS** issues during development.

```bash
flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=%TEMP%\\flutter_chrome_profile"
```

-----

## 📄 License

This project is licensed under the terms of the MIT License. See the `LICENSE` file for details.

## 👤 Contributor

  * **Muhammad Abdurrahman Rabbani** (Rahman/Hanif) - *Lead Developer*