
# HealthBuddy AI

[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Education Ready](https://img.shields.io/badge/Use%20Case-Education%20%7C%20Wellness-blueviolet)](#-education)

HealthBuddy AI is an advanced, multi-platform AI chat assistant built with Flutter. Powered by Google Gemini, this application offers a seamless, responsive, and interactive conversational experience across multiple devices.

> ℹ️ Replace the image placeholder below with your own screenshot or product mockup to enrich the repository landing page.

\<div align="center"\>
\<img src="[INSERT_SCREENSHOT_URL]" alt="HealthBuddy AI Screenshot" width="820"/\>
\</div\>

---

## 📚 Table of Contents

- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Education](#-education)
- [Getting Started](#getting-started)
- [Running the Application](#3-running-the-application)
- [Acknowledgements](#-acknowledgements)
- [License](#-license)
- [Contributor](#-contributor)

---

## 🚀 Key Features

- **Modern Glassmorphism UI:** Clean cards, vibrant gradients, and support for both light and dark modes.
- **3D AI Avatar:** Real-time GLB rendering (via `model_viewer_plus`) with intelligent idle/talking animation control for the web.
- **Streaming Responses:** Gemini responses appear word-by-word, creating a natural conversational flow.
- **Conversation Memory:** Keeps context across turns so the AI can deliver follow-up insights.
- **Full Voice Interaction:** Speech-to-text for input and text-to-speech playback in supported locales (defaults to Indonesian).
- **Persistent Chat History:** Conversations are saved locally using the blazing-fast Isar database.
- **Settings with Bilingual About:** English and Japanese app descriptions with proper asset credits and GitHub link.
- **Multi-Platform & Multi-Language:** Runs on Windows, Android, and Web with localized UI strings (EN, ID, JA).
- **Quick Actions:** Copy, share, and replay audio directly from each AI message bubble.

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

## Getting Started

This project requires a few specific setup steps due to its reliance on code generators and external APIs.

### 1\. Prerequisites

  * [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.x or newer)
  * A Code Editor (VS Code, Android Studio, etc.)
  * (For Android) Android SDK
  * (For Windows) Visual Studio 2022 with "Desktop development with C++" workload

### 2\. Installation & Setup

1.  **Clone the repository:**

  ```bash
  git clone https://github.com/Rabbani218/Buddy-AI.git
  cd Buddy-AI
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

## 📚 Education

HealthBuddy AI is designed as a teaching and demonstration tool for:

- **Digital Wellness Programs:** Show students how conversational AI can support healthy daily routines.
- **AI & Flutter Workshops:** Demonstrate real-time 3D rendering, Riverpod state management, and Gemini integration in one project.
- **Capstone Inspirations:** Provide a springboard for learners who want to extend the assistant with custom prompts, avatars, or data sources.
- **Language Practice:** Combine multilingual UI with voice capabilities to help users practice English, Indonesian, or Japanese conversations.

Educators are encouraged to fork the project, replace the prompt set with course-specific material, and provide localized content tailored to their cohorts.

---

## 🙌 Acknowledgements

- 3D avatar: ["FREE Annie anime gerl" by FibonacciFox (Sketchfab)](https://sketchfab.com/3d-models/free-annie-anime-gerl-490a8417cac946899eac86fba72cc210)
- Background gradient: [Photo by Plufow Le Studio (Unsplash)](https://unsplash.com/id/foto/gambar-buram-dari-latar-belakang-biru-dan-merah-muda-bUtAqPi-wz4)
- GitHub icon: [GitHub Mark](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png)

---

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE). You are free to use, modify, and distribute the code with proper attribution.

## 👤 Contributor

  * **Muhammad Abdurrahman Rabbani** (Rahman/Hanif) — *Lead Developer*