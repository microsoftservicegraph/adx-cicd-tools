#Requires -PSEdition Core

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
  Test-ADXDatabase -Verbose
#>
function Test-ADXDatabase {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
    Write-Log -Level INFO -Message "Test-ADXDatabase {0}" -Arguments $Category
  }
}

Export-ModuleMember -Function Test-ADXDatabase
