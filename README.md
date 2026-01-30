# **vibecheck.visualizer**

**Audio Visualization for KDE Plasma 6**

`vibecheck.visualizer` is a native KDE Plasma 6 widget (Plasmoid) that provides real-time audio visualization. It uses a dedicated C++ backend for signal processing to achieve low latency and reduced CPU usage compared to pure QML-based visualizers.

This project is built primarily as a learning and hobby effort, with a focus on native performance and clean integration with the KDE Plasma ecosystem.

---

## 🚀 Key Features

* **Low-Latency Audio Capture**
  Uses `libpulse-simple` for direct access to audio buffers with minimal overhead.

* **FFT-Based Visualization**
  Frequency analysis powered by **FFTW3** for accurate and responsive visuals.

* **Modern KDE Stack**
  Built with **Qt 6**, **KDE Frameworks 6**, and **Kirigami**.

* **Native Performance**
  Heavy computation runs in a C++ backend, keeping the QML UI smooth and responsive.

---

## ⚠️ Disclaimer

> **Project Disclaimer**
> This is my first KDE Plasma Plasmoid and a personal side project created mainly for learning and experimentation. I do not have prior professional experience in audio signal processing, DSP, or real-time audio visualization.
>
> As a result, the implementation may contain limitations, inefficiencies, or bugs, and may not follow best practices in all areas. The project works well for my personal use, but behavior and performance may vary across systems.
>
> Feedback, bug reports, and contributions are very welcome and appreciated.

---

## 🛠 Prerequisites

Install the required development headers before building.

### Core Dependencies

* **Frameworks**

  * Qt 6 (Core, QML, Quick)
  * KDE Frameworks 6 (Kirigami, Config, Plasma)

* **Build Tools**

  * CMake
  * Extra CMake Modules (ECM)

* **Libraries**

  * FFTW3
  * PulseAudio (`libpulse`)

---

## 🧩 Installation Commands

### Ubuntu / KDE Neon

```bash
sudo apt install build-essential cmake extra-cmake-modules \
qt6-base-dev qt6-declarative-dev \
libkf6kirigami-dev libkf6config-dev libplasma-dev \
libfftw3-dev libpulse-dev
```

### Arch Linux

```bash
sudo pacman -S base-devel cmake extra-cmake-modules \
qt6-declarative fftw libpulse libplasma kirigami
```

---

## 🏗 Build & Installation

This project includes a C++ QML plugin that must be compiled and installed into the system QML path.

### 1. Clone the repository

```bash
git clone https://github.com/shazwanx9/vibecheck.git
cd vibecheck
```

### 2. Build and install

```bash
cmake -B build -S . \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DKDE_INSTALL_USE_QT_SYS_PATHS=ON

cmake --build build
sudo cmake --install build
```

Alternatively, you can use the provided helper script:

```bash
./run.sh prod
```

### 3. Refresh Plasma

If the widget does not appear in the **Add Widgets** panel, restart the Plasma shell:

```bash
plasmashell --replace & disown
```

---

## 📂 Project Architecture

| Component        | Description                                      |
| ---------------- | ------------------------------------------------ |
| `src/`           | C++ backend for audio capture and FFT processing |
| `contents/`      | Kirigami-based QML UI, visuals, and icons        |
| `metadata.json`  | Plasmoid manifest and configuration              |
| `CMakeLists.txt` | Build and install configuration                  |
| `run.sh`         | Build and installation helper script             |

---

## 🔧 Troubleshooting

### ❌ No Audio Signal

* Ensure PulseAudio or PipeWire is running
* Confirm your user has access to audio devices
* Verify the correct default audio source is active

### ❌ Plugin Load Failure

Make sure the C++ plugin is installed into the correct Qt 6 QML path. You can test loading with:

```bash
qml6test -import /usr/lib/qt6/qml vibecheck.visualizer
```

If this fails, double-check your install prefix and `KDE_INSTALL_USE_QT_SYS_PATHS` setting.

---

## 📜 License

* **License:** GPL-2.0-or-later

---

## 🤝 Contributing & Contact

Contributions, bug reports, and suggestions are welcome — especially around audio handling, FFT logic, or UI improvements.

* **Issues:** Please open an issue for build or runtime problems
* **Pull Requests:** Improvements and cleanups are encouraged
* **Contact:** Reach out via GitHub or your preferred social platform