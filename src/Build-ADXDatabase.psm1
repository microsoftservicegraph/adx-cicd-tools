#Requires -PSEdition Core

Import-Module (Join-Path $PSScriptRoot adx-common.psm1) -Force

<#
.SYNOPSIS
  Build the ADX Database.
.DESCRIPTION
  Run the scripts to build the ADX Database. This expects the schema to be deployed already. Use fullname of the scripts
  to dictate the order of running the scripts.
.NOTES
  This expects the schema to be deployed already.
.LINK
  https://github.com/microsoftservicegraph/adx-cicd-tools
.EXAMPLE
  Build-ADXDatabase -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -BuildScriptsFolder .\build\
#>
function Build-ADXDatabase {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth = "Fed=True"
    , $BuildScriptsFolder
    , $Exclude = @()
    , [switch] $WhatIf
    )

  Process {
    Write-Log -Level INFO -Message "Build-ADXDatabase: Running with parameters:"
    Write-Log -Level INFO -Message "Cluster             : $Cluster"
    Write-Log -Level INFO -Message "Database            : $Database"
    Write-Log -Level INFO -Message "Auth                : $Auth"
    Write-Log -Level INFO -Message "BuildScriptsFolder  : $BuildScriptsFolder"
    Write-Log -Level INFO -Message "Exclude             : $($Exclude -join ",")"
    Write-Log -Level INFO -Message "WhatIf              : $WhatIf"

    $DateTimeStarted = ([System.DateTime]::UtcNow).ToString("yyyy-MM-dd HH:mm:ss")

    Write-Progress -Id 0 -Activity "Building ADX Database..." -Status "Running build scripts..." -PercentComplete 0

    $scripts = Get-ChildItem $BuildScriptsFolder -Recurse -Filter "*.kql" | Sort-Object -Property Name
    $scripts | ForEach-Object { $totalActions = $scripts.Length + 1; $completedActions = 0 } {
      $script = $_
      if (($Exclude | Where-Object { $script -Like $_ }).Length -ne 0) {
        Write-Host -ForegroundColor Yellow "Skipping: $script"
      } else {
        $script | ExecuteKustoScript $Cluster $Database $Auth -WhatIf:$WhatIf -Verbose:$Verbose
        $completedActions += 1
        [int] $percentComplete = $completedActions / $totalActions * 100
        Write-Progress -ParentId 0 -Id 1 -Activity "$($script.Name)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
      }
    }

    Write-Progress -ParentId 0 -Id 1 -Activity "Done..." -Completed

    Write-Progress -Id 0 -Activity "Building ADX Database" -Status "Writing build performance data..."  -PercentComplete 90
    $deployedOnCEST = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Central European Standard Time')
    $deployedOnPST = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Pacific Standard Time')
    $deployedBy = "$env:USERDOMAIN\\$env:USERNAME"
    $deployedCommit = git rev-parse HEAD
    $cluster = $Cluster
    $database = $Database

    ".set-or-replace BuildPerformance <|
        .show commands-and-queries
            | where Database == '$database'
            | where CommandType in ('TableAppend', 'TableReplace', 'TableSet', 'TableSetOrAppend', 'TableSetOrReplace')
            | where Application == 'Kusto.Cli'
            | where StartedOn > datetime('$DateTimeStarted')
            | extend MemoryPeakKBs = MemoryPeak / (1024)
            | extend TotalCpuMillis = tolong(TotalCpu/10000)
            | project ClientActivityId, Text, State, FailureReason, StartedOn, LastUpdatedOn, Duration, TotalCpu, TotalCpuMillis, MemoryPeak, MemoryPeakKBs, RootActivityId, User, Application, CacheStatistics
            | order by StartedOn
    " | ExecuteKustoCommand $Cluster $Database $Auth "add-ingest-performance" -WhatIf:$WhatIf -Verbose:$Verbose

    Write-Progress -Id 0 -Activity "Building ADX Database" -Status "Writing version information..."  -PercentComplete 95
    ".set-or-replace Version <| print DeployedOnUTC=now(), DeployedOnCEST='$deployedOnCEST',  DeployedOnPST='$deployedOnPST' , DeployedBy='$deployedBy', DeployedCommit='$deployedCommit', Cluster='$Cluster', Database='$Database'"
    | ExecuteKustoCommand $Cluster $Database $Auth "add-version-info" -WhatIf:$WhatIf -Verbose:$Verbose

    Write-Progress -Activity "Building ADX Database..." -Status "100% Complete:" -PercentComplete 100

    Write-Log -Level INFO -Message "Build-ADXDatabase done!"
  }
}

Export-ModuleMember -Function Build-ADXDatabase
