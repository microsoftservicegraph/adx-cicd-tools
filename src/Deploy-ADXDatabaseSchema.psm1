#Requires -PSEdition Core

Import-Module (Join-Path $PSScriptRoot adx-common.psm1) -Force

function RunScripts
{
  param (
    $Cluster
    , $Database
    , $Auth
    , $Id
    , $Scripts
  )

  Process {
    if (!$Scripts.Length) {
      continue
    }

    $Scripts | ForEach-Object { $totalActions = $Scripts.Length; $completedActions = 0 } {
      $_ | ExecuteKustoScript $Cluster $Database $Auth -WhatIf:$WhatIf -Verbose:$Verbose

      $completedActions += 1
      [int] $percentComplete = $completedActions / $totalActions * 100
      Write-Progress -ParentId 0 -Id $Id -Activity "$($_.Name)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
    }

    Write-Progress -ParentId 0 -Id $Id -Activity "Done..." -Completed
  }
}

$functionScriptTesterRegex = "^.*\\Functions\\.*\.kql$"

<#
.SYNOPSIS
  Deploy the ADX Database schema.
.DESCRIPTION
  Deploy the ADX Database schema. Whether the operation upsert / idempotent depends on how the individual kql files are
  written. E.g. .create-merge for tables to make operation upsert / idempotent.
.NOTES
  None.
.LINK
  https://github.com/microsoftservicegraph/adx-cicd-tools
.EXAMPLE
  Deploy-ADXDatabaseSchema -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -SchemaScriptsFolder .\schema\
#>
function Deploy-ADXDatabaseSchema {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth = "Fed=True"
    , $SchemaScriptsFolder
    , [switch] $WhatIf
  )

  Process {
    Write-Log -Level INFO -Message "Deploy-ADXDatabaseSchema: Running with parameters:"
    Write-Log -Level INFO -Message "Cluster             : $Cluster"
    Write-Log -Level INFO -Message "Database            : $Database"
    Write-Log -Level INFO -Message "Auth                : $Auth"
    Write-Log -Level INFO -Message "SchemaScriptsFolder : $SchemaScriptsFolder"
    Write-Log -Level INFO -Message "WhatIf              : $WhatIf"

    # 1. Create tables.
    Write-Progress -Id 0 -Activity "Deploying ADX Database schema..." -Status "Creating tables..." -PercentComplete 0
    $scripts = Get-ChildItem $SchemaScriptsFolder -Recurse -Filter "*.kql" | Where-Object { $_.FullName -inotmatch $functionScriptTesterRegex }
    RunScripts $Cluster $Database $Auth 1 $scripts

    # 2. Create functions.
    Write-Progress -Id 0 -Activity "Deploying ADX Database schema..." -Status "Creating functions..." -PercentComplete 40
    $scripts = Get-ChildItem $SchemaScriptsFolder -Recurse -Filter "*.kql" | Where-Object { $_.FullName -imatch $functionScriptTesterRegex }
    RunScripts $Cluster $Database $Auth 2 $scripts

    Write-Log -Level INFO -Message "Deploy-ADXDatabaseSchema done!"
  }
}

Export-ModuleMember -Function Deploy-ADXDatabaseSchema
