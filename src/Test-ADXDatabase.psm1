#Requires -PSEdition Core

Import-Module (Join-Path $PSScriptRoot adx-common.psm1) -Force

function GetCommand {
  param (
    [Parameter(ValueFromPipeline = $true)] $FileName
  )

  ($(Get-Content $FileName).Trim() -notmatch "^//") -join ' '
}

function RunCleanupForTests {
  param (
    $Cluster
    , $Database
    , $Auth
    , $TestFileName
    , [switch] $WhatIf
  )

  Process {
    $cleanupFileName = $TestFileName.Replace("test.kql", "cleanup.kql")
    if (Test-Path -Path $cleanupFileName) {
      Write-Log -Level INFO -Message "Running test cleanup: $($cleanupFileName)"
      $logFilePath = GetLogFilePath $Cluster $Database "$(Split-Path -Leaf $cleanupFileName)"
      ExecuteKustoCli $Cluster $Database $Auth "$cleanupFileName" @("-script:`"$cleanupFileName`"") $logFilePath -WhatIf:$WhatIf -Verbose:$Verbose
    }
  }
}

<#
.SYNOPSIS
  Run the tests on ADX Database.
.DESCRIPTION
  Tests are similar to Approval Tests.
.NOTES
  None.
.LINK
  https://github.com/microsoftservicegraph/adx-cicd-tools
.EXAMPLE
  Test-ADXDatabase -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -TestScriptsFolder .\tests\ -Filter * -Verbose
.EXAMPLE
  Test-ADXDatabase -Cluster 'adxcicdtools.germanywestcentral.kusto.windows.net' -Database 'testdb' -TestScriptsFolder .\tests\ -Filter * -Verbose -SaveApproved
#>
function Test-ADXDatabase {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth = "Fed=True"
    , $Filter = "*"
    , $TestScriptsFolder
    , [switch] $SaveApproved
    , [switch] $WhatIf
  )

  Process {
    $scripts = Get-ChildItem $TestScriptsFolder -Recurse -Filter "$Filter.test.kql" | Sort-Object -Property Name

    $totalTests = $scripts.Count
    $passedTests = 0
    $scripts | ForEach-Object { $completedTests = 0 } {
      $testFileName = $_.FullName
      RunCleanupForTests $Cluster $Database $Auth $testFileName -WhatIf:$WhatIf -Verbose:$Verbose

      $setupFileName = $testFileName.Replace("test.kql", "setup.kql")
      if (Test-Path -Path $setupFileName) {
        Write-Log -Level INFO -Message "Running test setup: $($setupFileName)"
        $logFilePath = GetLogFilePath $Cluster $Database "$(Split-Path -Leaf $setupFileName)"
        ExecuteKustoCli $Cluster $Database $Auth "$setupFileName" @("-script:`"$setupFileName`"") $logFilePath -WhatIf:$WhatIf -Verbose:$Verbose
      }
      Write-Log -Level INFO -Message "Running test: $($_.Name)"
      $command = GetCommand $_

      $recievedCsv = "$testFileName.recieved.csv"
      if ($SaveApproved) {
        Write-Log -Level INFO -Message "Saving received into approved for $($_.Name)"
        $recievedCsv = "$testFileName.approved.csv"
      }
      $logFilePath = GetLogFilePath $Cluster $Database "$($_.Name)"
      ExecuteKustoCli $Cluster $Database $Auth "$($_.Name)" @("-execute:`"#save $recievedCsv`"", "-execute:`"$command`"") $logFilePath -WhatIf:$WhatIf -Verbose:$Verbose

      $approvedCsv = "$testFileName.approved.csv"
      $expectedOutput = Get-Content -Path $approvedCsv -ErrorAction SilentlyContinue
      if (-not $expectedOutput) {
        "Check that you have created '$approvedCsv'. Recommend to run the test first time and copy recieved CSV." > $approvedCsv
        $expectedOutput = Get-Content -Path $approvedCsv
      }

      $recievedOutput = Get-Content -Path $recievedCsv
      if (-not $recievedOutput) {
        "Query failed or did not return anything. Check '$logFilePath'" > $recievedCsv
        $recievedOutput = Get-Content -Path $recievedCsv
      }

      $objects = @{
        ReferenceObject = $expectedOutput
        DifferenceObject = $recievedOutput
      }

      if (Compare-Object @objects) {
        Write-Log -Level ERROR -Message "... FAILED! To debug test failure run: code --diff '$approvedCsv' '$recievedCsv'"
      } else {
        Write-Log -Level INFO -Message "... PASSED."
        $passedTests += 1
      }

      RunCleanupForTests $Cluster $Database $Auth $testFileName -WhatIf:$WhatIf -Verbose:$Verbose

      $completedTests += 1
      [int] $percentComplete = $completedTests / $totalTests * 100
      Write-Progress -ParentId 0 -Id 1 -Activity "Running tests..." -Status "$($_.Name)" -PercentComplete $percentComplete
    }

    Write-Log -Level INFO -Message "Test-ADXDatabase done! $passedTests / $totalTests tests passed."
  }
}

Export-ModuleMember -Function Test-ADXDatabase
