[![Continuous Integration](https://github.com/parthopdas/adx-cicd-tools/workflows/Continuous%20Integration/badge.svg)](https://github.com/parthopdas/adx-cicd-tools/actions?query=workflow%3A%22Continuous+Integration%22) [![Publishing workflow](https://github.com/parthopdas/adx-cicd-tools/actions/workflows/publish.yml/badge.svg)](https://github.com/parthopdas/adx-cicd-tools/actions/workflows/publish.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# ADX CI/CD Tools

Bunch of PowerShell based tools for Continuos Integration & Continuos Deployment tools for Azure Data Explorer (a.k.a. Kusto) developed by the Service Graph team.

## Common commands

- Validate module definition
  ```Test-ModuleManifest .\src\adx-cicd-tools.psd1```
- Linting & static analysis
  ```
  Install-Module -Name PSScriptAnalyzer -Force;
  Invoke-ScriptAnalyzer -Path .\src -Recurse
  ```
- Test publishing process
  ```
  xcopy /frys .\src .\publish\adx-cicd-tools\
  Publish-Module -Path D:\src\gh\adx\publish\adx-cicd-tools -NuGetApiKey $nuGetApiKey -Verbose -WhatIf
  ```

## Backlog

- [ ] ADX deployment framework
- [ ] ADX test framework
- [ ] ADX prettiers, linters & analyzers
