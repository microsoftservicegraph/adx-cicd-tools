# ADX CI/CD Tools

Starter kit for ADX CI/CD Tools.

> NOTE: Duplicate the 'sample' folder as is, including the logs / bin folders and .keepme files. Follow the naming convention for the scripts.

## Commands

- Prepare
  ```
  cd sample
  Import-Module ..\src\adx-cicd-tools.psd1 -Force
  ```
- Clear database
  ```
  Clear-ADXDatabase -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -Exclude @()
  ```
- Deploy database schema
  ```
  Deploy-ADXDatabaseSchema -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -SchemaScriptsFolder .\schema\
  ```
- Build database
  ```
  Build-ADXDatabase -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -BuildScriptsFolder .\build\ -WhatIf
  ```
- Test database
  ```
  Test-ADXDatabase -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -TestScriptsFolder .\tests\ -Filter * -Verbose
  ```
