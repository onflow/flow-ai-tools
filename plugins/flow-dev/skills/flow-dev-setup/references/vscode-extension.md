# Cadence VS Code Extension

The Cadence VS Code extension provides language support for `.cdc` files in Visual Studio Code.

## Installation

Install from the VS Code Marketplace:
- Extension ID: `onflow.cadence`
- Search "Cadence" in the VS Code extensions panel, or run:

```bash
code --install-extension onflow.cadence
```

## Features

- **Syntax highlighting** — for `.cdc` files and Cadence code blocks in Markdown
- **Code completion** — IntelliSense for types, functions, and imports
- **Error checking** — Real-time diagnostics and type checking
- **Go to definition** — Navigate to contract and type definitions
- **Hover information** — Type information on hover
- **Emulator integration** — Connects to a running Flow Emulator for live feedback

## Configuration

The extension works out of the box with default settings. It automatically detects `flow.json` in the workspace root.

If the emulator is running, the extension uses it for enhanced type checking against deployed contracts.

## Building from Source

For development or custom builds:

```bash
npm install -g typescript
git clone https://github.com/onflow/vscode-cadence
cd vscode-cadence
npm install
npm run package
code --install-extension cadence-*.vsix
```

## Other Editors

For editors other than VS Code, the Cadence Language Server (bundled with Flow CLI) provides LSP support. Configure your editor's LSP client to use:

```bash
flow cadence language-server
```

## Documentation

- VS Code Marketplace: https://marketplace.visualstudio.com/items?itemName=onflow.cadence
- Official docs: https://developers.flow.com/tools/vscode-extension
