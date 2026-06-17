# English AI Study App

This is the codebase for the English AI Study App. The original design project is available on [Figma](https://www.figma.com/design/L1ax1bXPQZMpmH2q2jAKhG/English-AI-Study-App).

## How to Set Up and Run on Another Computer

If you want to open and run this project on a different computer, follow these steps:

### 1. Prerequisites
Before starting, make sure the new computer has the following installed:
* **Git**: [Download and Install Git](https://git-scm.com/)
* **Flutter SDK**: Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install) for your OS.
* **VS Code** (or Android Studio): With the **Flutter** and **Dart** extensions installed.

---

### 2. Step-by-Step Setup Flow

1. **Clone the repository**:
   Open a terminal on the new computer and clone the project:
   ```bash
   git clone https://github.com/PANHA006/mobile-app-flutter-project
   ```

2. **Navigate into the project directory**:
   ```bash
   cd mobile-app-flutter-project
   ```

3. **Install Dependencies**:
   Run this command to fetch all the required Flutter packages:
   ```bash
   flutter pub get
   ```

4. **Verify the Flutter Environment**:
   Ensure your setup and target devices (Emulator, Web, or Physical device) are ready:
   ```bash
   flutter doctor
   ```

5. **Run the Application**:
   Start the development server and run the app:
   ```bash
   flutter run
   ```

### 3. Running the Backend Server (AI Chat)

The chat feature relies on a local Node.js backend to communicate with the Gemini API securely.

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment Variables**:
   Create a `.env` file inside the `backend` directory and add your Gemini API Key:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Start the backend server**:
   ```bash
   npm start
   ```
   The server will run on `http://localhost:3000` (or `http://10.0.2.2:3000` for Android emulators).

