# Advanced Desktop BLE Monitor

A premium, high-performance Flutter desktop application designed for real-time Bluetooth Low Energy (BLE) telemetry and monitoring. Built specifically for Windows, this tool provides a professional-grade interface for interacting with BLE servers (such as ESP32, Arduino, or custom embedded modules).

## 🚀 Overview

The **BLE Monitor Dashboard** is designed to bridge the gap between embedded BLE devices and desktop analysis. It allows developers to scan, connect, and visualize data streams in real-time, making it an essential tool for debugging BLE-based sensor systems, robotics, and IoT prototypes.

This app is part of a dual-repo ecosystem, intended to be used alongside a dedicated **BLE Server Module** (Embedded C/C++) to provide a complete end-to-end monitoring solution.

## ✨ Key Features

- **📡 Advanced Scanner**: Robust device discovery with signal strength (RSSI) monitoring and name filtering.
- **📊 Real-time Data Monitor**: An integrated oscilloscope-style visualization tab capable of plotting high-frequency data streams using hardware-accelerated charts.
- **🏠 Integrated Dashboard**: A centralized view for device status, connection stability, and core metrics.
- **💾 CSV Data Logging**: Capture and export received BLE data directly to CSV files for post-processing and analysis.
- **🎨 Premium UI/UX**: Dark-themed, modern interface built with Flutter's Material 3 design system, optimized for desktop use.

## 🛠️ Prerequisites & Dependencies

Before you can build and run this application, ensure you have the following installed on your system:

### 1. Flutter SDK
- Install the latest stable version of [Flutter](https://docs.flutter.dev/get-started/install/windows).
- Ensure `flutter` is added to your system's PATH.

### 2. Visual Studio 2022
- Required for building Windows desktop applications.
- During installation, you **MUST** select the **"Desktop development with C++"** workload.
- Ensure the following components are included:
  - MSVC v143 - VS 2022 C++ x64/x86 build tools
  - Windows 10/11 SDK (latest)

### 3. Git
- [Git for Windows](https://git-scm.com/download/win) is required for dependency management and version control.

### 4. Windows Hardware Requirements
- **OS**: Windows 10 version 1809 or higher (required for WinRT BLE support).
- **Hardware**: A Bluetooth 4.0 (or higher) adapter.

---

## 🏗️ Getting Started & Build Commands

Follow these steps to set up the project locally:

### 📥 1. Clone the Repository
```bash
git clone https://github.com/your-username/ble_desktop_app.git
cd ble_desktop_app
```

### 📦 2. Initialize Dependencies
Download all the necessary Flutter packages defined in `pubspec.yaml`:
```bash
flutter pub get
```

### 🧹 3. Cleaning the Build
If you encounter build errors or want to perform a fresh compilation:
```bash
flutter clean
```

### 🚀 4. Running the App
To start the application in debug mode:
```bash
flutter run -d windows
```

#### Interactive Development Commands:
While the app is running in the terminal, you can use these shortcuts:
- **`r`**: **Hot Reload** — Quickly updates UI changes without losing app state.
- **`R`**: **Hot Restart** — Fully restarts the app (useful for state-level changes).
- **`p`**: Toggle performance overlay.
- **`q`**: Quit the application.

### 📦 5. Building for Production
To generate a standalone executable for distribution:
```bash
flutter build windows
```
The compiled output will be located in:
`build\windows\x64\runner\Release\`

---

## 🤝 Relationship with BLE Module
This desktop application expects a BLE Server with a specific characteristic protocol for optimal data streaming. A separate repository containing the **Self-Contained BLE Embedded App** (ESP32/NimBLE) will be provided shortly to serve as the perfect companion for this dashboard.

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.