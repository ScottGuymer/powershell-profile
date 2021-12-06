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

function Set-AWSRole([String]$awsprofile, [string]$role) {

  Write-Output "Logging into AWS using credential profile $awsprofile and assuming role $role"  

  $env:_AWS_ACCESS_KEY_ID=$env:AWS_ACCESS_KEY_ID
  $env:_AWS_SECRET_ACCESS_KEY=$env:AWS_SECRET_ACCESS_KEY
  $env:_AWS_SESSION_TOKEN=$env:AWS_SESSION_TOKEN

  try {
    $aws_credentials=$(aws sts assume-role --profile $awsprofile --role-arn $role --role-session-name $($(whoami) -Replace '[^a-zA-Z0-9]',''))

    $json = $aws_credentials | ConvertFrom-Json
    $env:AWS_ACCESS_KEY_ID=$json.Credentials.AccessKeyId
    $env:AWS_SECRET_ACCESS_KEY=$json.Credentials.SecretAccessKey
    $env:AWS_SESSION_TOKEN=$json.Credentials.SessionToken    
  }
  catch {
    Write-Host -ForegroundColor Red "Error assuming role $role."
    Write-host -ForegroundColor Red  "Error: $($_.Exception.Message)"
    exit 1  
  }

  Write-Host -ForegroundColor Green "Role Assumed"
}

function Clear-AWSRole([String]$role) {

  $env:AWS_ACCESS_KEY_ID=$env:_AWS_ACCESS_KEY_ID
  $env:AWS_SECRET_ACCESS_KEY=$env:_AWS_SECRET_ACCESS_KEY
  $env:AWS_SESSION_TOKEN=$env:_AWS_SESSION_TOKEN

  $env:_AWS_ACCESS_KEY_ID=""
  $env:_AWS_SECRET_ACCESS_KEY=""
  $env:_AWS_SESSION_TOKEN=""

  Write-Host -ForegroundColor Green "Cleared assumed role."
}
function set-AWSProfile([String]$role) {
  $env:AWS_PROFILE=$([String]$role) 

  Write-Host -ForegroundColor Green "Changed to $role profile."
}

function Clear-AWSProfile()  {
  $env:AWS_PROFILE=""

  Write-Host -ForegroundColor Green "Cleared profile."
}
