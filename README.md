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

## Overview

<!-- DETAILED_OVERVIEW: 2-3 paragraphs explaining what the project does, why it exists, and how it fits into the ecosystem -->
<!-- Include: problem it solves, approach taken, key technologies used -->
<!-- Example: "The UpdateController is a Kubernetes-native controller that solves the challenge of keeping game servers up-to-date in a containerized environment. It leverages the ghcr.io/udl-tf/tf2-image container which includes SteamCMD for update management." -->

{{DETAILED_OVERVIEW}}

### Key Responsibilities

<!-- List 3-5 main responsibilities or capabilities of the project -->
<!-- Format: Action verb (Monitor, Update, Restart, etc.) with description -->
<!-- RESPONSIBILITY_X: Single word action/category (e.g., "Monitor", "Update", "Deploy") -->
<!-- RESPONSIBILITY_X_DESCRIPTION: Brief explanation of what that responsibility entails -->

- **{{RESPONSIBILITY_1}}**: {{RESPONSIBILITY_1_DESCRIPTION}}
- **{{RESPONSIBILITY_2}}**: {{RESPONSIBILITY_2_DESCRIPTION}}
- **{{RESPONSIBILITY_3}}**: {{RESPONSIBILITY_3_DESCRIPTION}}
- **{{RESPONSIBILITY_4}}**: {{RESPONSIBILITY_4_DESCRIPTION}}

## Architecture

<!-- ARCHITECTURE_DIAGRAM: A Mermaid diagram showing the system architecture -->
<!-- Should be a complete Mermaid graph definition (graph TB, graph LR, etc.) -->
<!-- Include: main components, external dependencies, data flow, and relationships -->
<!-- Use subgraphs for logical groupings, style nodes for visual clarity -->

```mermaid
{{ARCHITECTURE_DIAGRAM}}
```

## How It Works

<!-- WORKFLOW_NAME: Name of the primary workflow/process (e.g., "Update Check", "Deployment Pipeline") -->

### {{WORKFLOW_NAME}} Flow

<!-- SEQUENCE_DIAGRAM: A Mermaid sequence diagram showing the step-by-step workflow -->
<!-- Should be a complete Mermaid sequenceDiagram definition -->
<!-- Include: participants, message flows, alt/opt blocks for conditionals, autonumber for clarity -->

```mermaid
{{SEQUENCE_DIAGRAM}}
```

<!-- STATE_MACHINE_NAME: Name of the state machine (e.g., "Controller State Machine", "Deployment Lifecycle") -->

### {{STATE_MACHINE_NAME}}

<!-- STATE_DIAGRAM: A Mermaid state diagram showing all possible states and transitions -->
<!-- Should be a complete Mermaid stateDiagram-v2 definition -->
<!-- Include: all states, transitions with conditions, initial and terminal states -->

```mermaid
{{STATE_DIAGRAM}}
```

## Features

<!-- List 5-10 key features of the project -->
<!-- FEATURE_X: Short feature name (e.g., "Automatic Update Detection", "Smart Pod Selection") -->
<!-- FEATURE_X_DESCRIPTION: Detailed explanation of the feature, including technical details -->

- **{{FEATURE_1}}**: {{FEATURE_1_DESCRIPTION}}
- **{{FEATURE_2}}**: {{FEATURE_2_DESCRIPTION}}
- **{{FEATURE_3}}**: {{FEATURE_3_DESCRIPTION}}
- **{{FEATURE_4}}**: {{FEATURE_4_DESCRIPTION}}
- **{{FEATURE_5}}**: {{FEATURE_5_DESCRIPTION}}
- **{{FEATURE_6}}**: {{FEATURE_6_DESCRIPTION}}
- **{{FEATURE_7}}**: {{FEATURE_7_DESCRIPTION}}
- **{{FEATURE_8}}**: {{FEATURE_8_DESCRIPTION}}
- **{{FEATURE_9}}**: {{FEATURE_9_DESCRIPTION}}
- **{{FEATURE_10}}**: {{FEATURE_10_DESCRIPTION}}

## Prerequisites

<!-- List all requirements needed before installation -->
<!-- Include: platform versions, dependencies, access requirements, infrastructure needs -->
<!-- PREREQUISITE_X: Each prerequisite with version info if applicable -->
<!-- Example: "Kubernetes cluster (v1.25+)", "Go 1.25+ (for development)" -->

- {{PREREQUISITE_1}}
- {{PREREQUISITE_2}}
- {{PREREQUISITE_3}}
- {{PREREQUISITE_4}}
- {{PREREQUISITE_5}}

## Installation

<!-- Installation instructions based on project. -->

## Configuration

### Environment Variables

<!-- ENVIRONMENT_VARIABLES_TABLE: Complete table rows for environment variables -->
<!-- Format: Each row should be: | `VARIABLE_NAME` | Description here | `default_value` | Yes/No | -->
<!-- Example: | `CHECK_INTERVAL` | Interval between update checks | `30m` | No | -->
<!-- Include all configurable environment variables with their descriptions, defaults, and required status -->

| Variable | Description | Default | Required |
| -------- | ----------- | ------- | -------- |

{{ENVIRONMENT_VARIABLES_TABLE}}

## Development

### Project Structure

<!-- PROJECT_STRUCTURE: Complete directory tree showing project layout -->
<!-- Format: Use proper indentation with ├── and └── for tree structure -->
<!-- Include main directories, key files, and brief inline comments -->
<!-- Example:
├── cmd/
│   └── controller/          # Main controller application
│       └── main.go
├── internal/
│   ├── controller/          # Controller logic
│   └── client/              # Client implementations
├── deploy/                  # Kubernetes manifests
├── Dockerfile
└── README.md
-->

```
{{PROJECT_NAME}}/
{{PROJECT_STRUCTURE}}
```

## License

See [LICENSE](LICENSE) file for details.

## Dependencies

<!-- DEPENDENCIES_LIST: List of key project dependencies with links and descriptions -->
<!-- Format: Markdown list with links to dependency repositories/docs -->
<!-- Example:
- [TF2Image](https://github.com/UDL-TF/TF2Image) - The base TF2 server image
- [client-go](https://github.com/kubernetes/client-go) - Kubernetes Go client library
- [cobra](https://github.com/spf13/cobra) - CLI framework
-->

{{DEPENDENCIES_LIST}}
