#Requires -PSEdition Core

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
  Clear-ADXDatabase -Verbose
#>
function Clear-ADXDatabase {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
    Write-Log -Level INFO -Message "Clear-ADXDatabase {0}" -Arguments $Category
  }
}

Export-ModuleMember -Function Clear-ADXDatabase
