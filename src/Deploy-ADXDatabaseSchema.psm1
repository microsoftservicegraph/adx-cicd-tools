#Requires -PSEdition Core

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
  Deploy-ADXDatabaseSchema -Verbose
#>
function Deploy-ADXDatabaseSchema {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
    Write-Log -Level INFO -Message "Deploy-ADXDatabaseSchema {0}" -Arguments $Category
  }
}

Export-ModuleMember -Function Deploy-ADXDatabaseSchema
