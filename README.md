<!-- PROJECT_NAME: The name of the project (e.g., "UpdateController", "GameServerManager") -->

# TF2 Dodgeball Practice Bot

<!-- SHORT_DESCRIPTION: A single sentence describing what the project does and its primary purpose -->
<!-- Example: "A Kubernetes controller written in Go that automatically manages updates for Team Fortress 2 (TF2) game servers running in a cluster." -->

{{SHORT_DESCRIPTION}}

<!-- If projects needs badges use them, below is a example that could be used. -->
<!-- GO_VERSION: The minimum or target Go version (e.g., "1.25", "1.21") -->
<!-- LICENSE: License type (e.g., "MIT", "Apache-2.0", "GPL-3.0") -->
<!-- [![Go Version](https://img.shields.io/badge/Go-{{GO_VERSION}}-blue.svg)](https://golang.org/)
[![License](https://img.shields.io/badge/license-{{LICENSE}}-green.svg)](LICENSE) -->

# Convars
```ini
    tf_bot_enable           "1"     - Enable/disable player vs bot mode.
    tf_bot_vote_cooldown    "120"   - Cooldown time for the voting command.
    tf_bot_team             "2"     - The default team for the bot, 2 - Red, 3 - Blu.
    tf_bot_autojoin         "1"     - Enable/ disable autojoin for bot when a player joins the server.
```
# Requirements
- [Multi-Colors](https://github.com/Bara/Multi-Colors) (compile only).
- [TF2Dodgeball](https://github.com/Silorak/TF2-Dodgeball-Modified) it's a mandatory requirement not just for compiling also for functioning.

# Installation
Copy the (ex. `Sourcemod`) folder into `tf/addons`
Make sure the `dodgeball_bot_targets` config file is in `tf/addons/confis/dodgeball`