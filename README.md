# Wheel of Fortune Tracker + Guarantee

This mod for Balatro will either:

- Track your Nope! rate for The Wheel of Fortune, adding metrics to the card display, or
- Guarantee the "1 in 4" success rate for The Wheel of Fortune, such that The Wheel cannot Nope! you more than 3 times in a row

The metrics reset when Balatro.exe launches and aren't saved. Starting a new game will not affect the tracker.

Tracker mode:

![rates](rates.png)

Guarantee mode:

![freebie](freebie.png)

Refer to [PityWheel.lua](PityWheel.lua) for configuration details and usage hints.

## Installation

1. Install [Steammodded](https://github.com/Steamopollys/steamodded)
2. Put PityWheel.lua into your Mods folder
3. Modify the config section at the top of PityWheel.lua according to your preferences

Alternatively, If you want the wheel stats to be saved between game sessions, download PityWheel.lua and wheel_save.txt from https://github.com/Norad74/pitywheel. Put PityWheel.lua in your mods folder and wheel_save.txt to your %appdata%/Balatro folder

