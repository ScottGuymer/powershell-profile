function Set-NVMVersion { 
  $exists = Test-Path .nvmrc

  if($exists) {
    nvm install $(Get-Content .nvmrc); 
    nvm use $(Get-Content .nvmrc);
  }
  else {
    Write-Host ".nvmrc file does not exist in this directory."
  }
 }

function touch($filename) {
  New-Item -ItemType file $filename
}

function tail([String]$filename, [int]$lines = 10) {
  Get-Content $filename -Wait -Tail $lines
}

function Optimize-Docker-Images {
  Write-Host "Removing all stopped docker containers" -ForegroundColor Green
  docker rm $(docker ps -a -q)
  Write-Host "Removing all dangling images" -ForegroundColor Green
  docker rmi $(docker images --filter "dangling=true" -a -q)
}

function base64encode() {
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline)] $Text
  )
  $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
  $EncodedText =[Convert]::ToBase64String($Bytes)
  return $EncodedText
}

function base64decode() {
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline)] $Text
  )
  $Bytes = [Convert]::FromBase64String($Text)
  $DecodedText = [System.Text.Encoding]::Unicode.GetString($Bytes)
  return $DecodedText
}


