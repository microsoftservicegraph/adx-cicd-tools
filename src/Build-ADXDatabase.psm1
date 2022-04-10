#Requires -PSEdition Core

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
  Build-ADXDatabase -Verbose
#>
function Build-ADXDatabase {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
    Write-Log -Level INFO -Message "Build-ADXDatabase {0}" -Arguments $Category
  }
}

Export-ModuleMember -Function Build-ADXDatabase
