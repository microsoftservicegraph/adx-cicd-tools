#Requires -PSEdition Core

Import-Module (Join-Path $PSScriptRoot adx-common.psm1) -Force

$NameRecordNames = @{
  "function" = "Name";
  "table" = "TableName";
}

$MaxBatchSize = 30

function NukeEntities
{
  param (
    $Cluster
    , $Database
    , $Auth
    , $ProgressId
    , $Entity
  )

  Process {
    $resultsCsv = GetScopedBinFilePath $Cluster $Database "all$($Entity)s.csv"
    $logFilePath = GetLogFilePath $Cluster $Database "all$($Entity)s"
    Write-Log -Level INFO -Message "Getting list of all $($Entity)s..."
    ExecuteKustoCli $Cluster $Database $Auth "Fetch all $($Entity)s" @("-execute:`"#save $($resultsCsv)`"", "-execute:`".show $($Entity.ToLower())s`"") $logFilePath -Verbose:$Verbose
    $filteredEntityNames = Import-Csv $resultsCsv
      | ForEach-Object { $_."$($NameRecordNames[$Entity])" }
      | ForEach-Object {
        $entityName = $_
        if (($Exclude | Where-Object { $entityName -Like $_ }).Length -ne 0) {
          Write-Log -Level WARNING -Message "Skipping $($Entity): $entityName"
        } else {
          if ($entityName -eq "CrossBoundaryAlertsSnapshot") {
            Write-Log -Level WARNING -Message "Skipping $($Entity): $entityName"
          } else {
            $_
          }
        }
      }

    $i = 0
    while ($($MaxBatchSize * $i) -lt $filteredEntityNames.Length) {
      $group = $filteredEntityNames | Select-Object -First $MaxBatchSize -skip ($MaxBatchSize * $i)
      $command = ".drop $($Entity.ToLower())s ($($group -join ","))"
      $command | ExecuteKustoCommand $Cluster $Database $Auth "drop-$($Entity.ToLower())s-$i" -WhatIf:$WhatIf -Verbose:$Verbose

      $i++
      [int]$percentComplete = [Math]::Min(100, ($MaxBatchSize * $i) / $filteredEntityNames.Length * 100)
      Write-Progress -ParentId 0 -Id $ProgressId -Activity "Nuking $($Entity.ToLower())s..." -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
    }

    Write-Progress -ParentId 0 -Id $ProgressId -Activity "Done..." -Completed
  }
}

<#
.SYNOPSIS
  Wipe out the contents of the ADX Database.
.DESCRIPTION
  Delete all tables and functions from the given ADX Database.
.NOTES
  This is a destructive operation. Use with care.
.LINK
  https://github.com/microsoftservicegraph/adx-cicd-tools
.EXAMPLE
  Clear-ADXDatabase -Cluster "" -
#>
function Clear-ADXDatabase {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth = "Fed=True"
    , $Exclude = @("Products")
    , [switch] $WhatIf
  )

  Process {
    Write-Log -Level INFO -Message "Clear-ADXDatabase: Running with parameters:"
    Write-Log -Level INFO -Message "Cluster   : $Cluster"
    Write-Log -Level INFO -Message "Database  : $Database"
    Write-Log -Level INFO -Message "Auth      : $Auth"
    Write-Log -Level INFO -Message "Exclude   : $($Exclude -join ",")"
    Write-Log -Level INFO -Message "WhatIf    : $WhatIf"

    Write-Progress -Id 0 -Activity "Clearing functions..." -PercentComplete 0
    NukeEntities $Cluster $Database $Auth 1 "Function"
    Write-Progress -Id 0 -Activity "Clearing tables..." -PercentComplete 50
    NukeEntities $Cluster $Database $Auth 2 "Table"

    Write-Log -Level INFO -Message "Clear-ADXDatabase done!"
  }
}

Export-ModuleMember -Function Clear-ADXDatabase
