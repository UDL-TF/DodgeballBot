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
    tfdb_bot_enable           "1"     - Enable/disable player vs bot mode.
    tfdb_bot_vote_cooldown    "120"   - Cooldown time for the voting command.
    tfdb_bot_team             "2"     - The default team for the bot, 2 - Red, 3 - Blu.
    tfdb_bot_autojoin         "1"     - Enable/ disable autojoin for bot when a player joins the server.
```
# Requirements
- [Multi-Colors](https://github.com/Bara/Multi-Colors) only for compiling.
- [TF2Dodgeball](https://github.com/Silorak/TF2-Dodgeball-Modified) is a mandatory requirement not just for compiling also for functioning.

# Installation
Copy the `plugins` folder into `tf/addons/sourcemod/plugins` and `configs` folder into `tf/addons/sourcemod/configs`.
In the `translations` folder the `tfdb_bot.phrases`'s contents go into `tfdb.phrases`.

# Features
This bot plugin aims to reproduce most of the movement a typical player does, this enables players to practice the playstyle that fits them most.
It can move around on maps (only exception if the map is not centered around (0;0;0) coordinate or has places where it can fall down), or you can also choose to fix the bot to a specific coordinate.
In the config file I'll try to include predefined coordinates for most maps where the "player mimic" function would not be ideal.

# Credits
- Bot core functions (movement and flick) is based on Elite's work.
- Map target position functions added by Benedevil.