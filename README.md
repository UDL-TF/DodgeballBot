<!-- PROJECT_NAME: The name of the project (e.g., "UpdateController", "GameServerManager") -->

<!--# TF2 Dodgeball Practice Bot -->

<!-- SHORT_DESCRIPTION: A single sentence describing what the project does and its primary purpose -->
<!-- Example: "A Kubernetes controller written in Go that automatically manages updates for Team Fortress 2 (TF2) game servers running in a cluster." -->

<!-- If projects needs badges use them, below is a example that could be used. -->
<!-- GO_VERSION: The minimum or target Go version (e.g., "1.25", "1.21") -->
<!-- LICENSE: License type (e.g., "MIT", "Apache-2.0", "GPL-3.0") -->
<!-- [![Go Version](https://img.shields.io/badge/Go-{{GO_VERSION}}-blue.svg)](https://golang.org/)
[![License](https://img.shields.io/badge/license-{{LICENSE}}-green.svg)](LICENSE) -->

# Convars
```ini
    tf_dodgeball_bot_enable           "1"     - Toggle player vs bot mode.
    tf_dodgeball_bot_vote_cooldown    "120"   - Cooldown time for the voting command.
    tf_dodgeball_bot_team             "3"     - The default team for the bot, 2 - Red, 3 - Blu.
    tf_dodgeball_bot_autojoin         "1"     - Enable/disable autojoin for bot when a player joins the server.
    tf_dodgeball_bot_cleanbots        "1"     - Should this plugin kick bots when it's not active?
```
# Requirements
- [Multi-Colors](https://github.com/Bara/Multi-Colors) only for compiling.
- [TF2Dodgeball](https://github.com/Silorak/TF2-Dodgeball-Modified) is a mandatory requirement not just for compiling also for functioning.

# Installation
Copy the extra phrases from `extra_translations.txt` into the `tfdb.phrases.txt` file.

# Commands
- sm_pvb : Toggles Player vs. Bot mode.
- sm_votepvb : Starts a vote to toggle Player vs. Bot mode.

# Features
This bot plugin aims to reproduce most of the movement a typical player does, this enables players to practice the playstyle that fits them most.
It can move around on maps (only exception if the map is not centered around (0;0;0) coordinate or has places where it can fall down), or you can also choose to fix the bot to a specific coordinate.
In the config file I'll try to include predefined coordinates for most maps to fix the bot where the "player mimic" function would not be ideal.

When you are alone on the server you are able to vote to enable the bot without the cooldown.

# Issues
It's not comletetly unbeatable, there are (very) few instances where it tries to orbit a rocket that is not actually orbitable. But it's currently getting worked on!

Can't play against multiple players, sadly tf2's built in AI overwrites the angle where the bot is looking and causing it to miss rockets.

# Credits
- Bot core functions (movement and flick) is based on Elite's work.
- Map target position functions added by Benedevil.