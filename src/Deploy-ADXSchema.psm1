#Requires -PSEdition Core

function Deploy-ADXSchema {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
  }
}

Export-ModuleMember -Function Deploy-ADXSchema
