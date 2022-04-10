[![Continuous Deployment](https://github.com/microsoftservicegraph/adx-cicd-tools/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/microsoftservicegraph/adx-cicd-tools/actions/workflows/ci.yml) [![Publish](https://github.com/microsoftservicegraph/adx-cicd-tools/actions/workflows/publish.yml/badge.svg?branch=master)](https://github.com/microsoftservicegraph/adx-cicd-tools/actions/workflows/publish.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# ADX CI/CD Tools

Bunch of PowerShell based tools for Continuos Integration, Continuos Testing, & Continuos Deployment tools for Azure Data Explorer (a.k.a. Kusto) developed by the Service Graph team.

## Common commands

### Building PowerShell Module

- Install dependencies
  ```
  Install-Module -Name Logging -RequiredVersion 4.8.5 -Force
  Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.20.0 -Force
  ```
- Validate module definition
  ```
  Test-ModuleManifest .\src\adx-cicd-tools.psd1 | Format-List
  ```
- Linting & static analysis
  ```
  $issues = @(); Invoke-ScriptAnalyzer -Path .\src -Recurse | Tee-Object -Variable issues; if ($issues) { throw "PSScriptAnalyzer has detected $($issues.Length) issue(s)." }
  ```
- Test publishing process
  ```
  xcopy /frys .\src .\publish\adx-cicd-tools\
  Publish-Module -Path D:\src\gh\adx\publish\adx-cicd-tools -NuGetApiKey $nuGetApiKey -Verbose -WhatIf
  ```

### Testing PowerShell Module

See [Sample](./sample/README.md) README.

## Backlog

- [ ] ADX deployment framework
- [ ] ADX test framework
- [ ] Support environments in scripts
- [ ] ADX prettiers, linters & analyzers - abstract code from Kusto Explorer

