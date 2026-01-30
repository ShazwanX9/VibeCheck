🐛 Known Issues & Quirks
🔊 Volume Dependency (The "Gain" Bug)

    Behavior: The visualizer's height is directly affected by the system volume of the active output device.

    The Issue: If you mute the speaker or lower the volume on a different output, the visualizer will flatten even if audio is "playing" at the source level.

    Status: Logic currently captures the post-fader monitor stream. A future update is needed to tap into the pre-fader stream or normalize the buffer based on current sink volume.

    Developer's Note: I personally prefer post-audio capture. It matches the user's immediate expectation—if there’s no sound, there’s no movement. More importantly, it acts as a diagnostic tool; it can detect audio leakage or background noise that shouldn't be there, which a pre-fader visualizer would hide.

    Counter Argument: high-gain microphones or messy ground loops might cause flickering

🎨 Theming & Security

    Implementation Note: Themes are currently hardcoded or handled via QML properties.

    Security Choice: I have intentionally avoided using external JSON files for theme injection. This avoids requiring XCR or extra filesystem permissions, keeping the Plasmoid "low-trust" and safer for the end-user.

    Developer's Note: Keeping it "low-trust" is a priority. I want users to be able to install this Plasmoid without worrying about what my tool is reading or writing in the background. Your security and system integrity come before fancy configuration files.