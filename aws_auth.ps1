function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

$profilesScriptBlock = { Get-IniContent("~/.aws/config") | Select-Object -ExpandProperty Keys | ForEach-Object { $_.Replace("profile ","") }  | out-string -stream }

function Set-AWSRole([String]$awsprofile, [string]$role) {

  Write-Output "Logging into AWS using credential profile $awsprofile and assuming role $role"  

  $env:_AWS_ACCESS_KEY_ID=$env:AWS_ACCESS_KEY_ID
  $env:_AWS_SECRET_ACCESS_KEY=$env:AWS_SECRET_ACCESS_KEY
  $env:_AWS_SESSION_TOKEN=$env:AWS_SESSION_TOKEN

  $aws_credentials=$(aws sts assume-role --profile $awsprofile --role-arn $role --role-session-name $($(whoami) -Replace '[^a-zA-Z0-9]',''))


  if( $LASTEXITCODE -eq 0 ) {          
    $json = $aws_credentials | ConvertFrom-Json
    $env:AWS_ACCESS_KEY_ID=$json.Credentials.AccessKeyId
    $env:AWS_SECRET_ACCESS_KEY=$json.Credentials.SecretAccessKey
    $env:AWS_SESSION_TOKEN=$json.Credentials.SessionToken    
  } else {      
    throw "Error starting session"  
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

function Set-AWSProfile([String]$awsprofile) {
  $env:AWS_PROFILE=$([String]$awsprofile) 

  Write-Host -ForegroundColor Green "Changed to $awsprofile profile."
}
Register-ArgumentCompleter -CommandName Set-AWSProfile -ParameterName awsprofile -ScriptBlock $profilesScriptBlock

function Clear-AWSProfile()  {
  $env:AWS_PROFILE=""

  Write-Host -ForegroundColor Green "Cleared profile."
}

function Start-AWSMFASession () {

  $awsConfig = Get-IniContent("~/.aws/config")

  $awsprofile = $env:AWS_PROFILE
  
  if(-not $awsprofile) 
  {
      $awsprofile = "default"
  }
  
  Write-Host "Your current AWS profile is $awsprofile"
  
  $profileConfig = $awsConfig["profile $awsprofile"]
  
  if(-not $profileConfig)
  {
      write-host "Your profile is empty"
      return
  }
  
  if(-not $profileConfig["mfa_serial"])
  {
      write-host "have no mfa_serial in your profile"
      return
  }
  
  $mfacode = Read-Host "please enter your MFA code"
  

  Write-Output "Starting MFA session"  

  $env:_AWS_ACCESS_KEY_ID=$env:AWS_ACCESS_KEY_ID
  $env:_AWS_SECRET_ACCESS_KEY=$env:AWS_SECRET_ACCESS_KEY
  $env:_AWS_SESSION_TOKEN=$env:AWS_SESSION_TOKEN

  $env:AWS_ACCESS_KEY_ID=""
  $env:AWS_SECRET_ACCESS_KEY=""
  $env:AWS_SESSION_TOKEN=""

  $aws_credentials=$(aws sts get-session-token --serial-number $profileConfig.mfa_serial --token-code $mfacode)  

  if( $LASTEXITCODE -eq 0 ) {          
    $json = $aws_credentials | ConvertFrom-Json
    $env:AWS_ACCESS_KEY_ID=$json.Credentials.AccessKeyId
    $env:AWS_SECRET_ACCESS_KEY=$json.Credentials.SecretAccessKey
    $env:AWS_SESSION_TOKEN=$json.Credentials.SessionToken    
  } else {      
    throw "Error starting session"  
  }
}

function Stop-AWSMFASession() {

  $env:AWS_ACCESS_KEY_ID=$env:_AWS_ACCESS_KEY_ID
  $env:AWS_SECRET_ACCESS_KEY=$env:_AWS_SECRET_ACCESS_KEY
  $env:AWS_SESSION_TOKEN=$env:_AWS_SESSION_TOKEN

  $env:_AWS_ACCESS_KEY_ID=""
  $env:_AWS_SECRET_ACCESS_KEY=""
  $env:_AWS_SESSION_TOKEN=""

  Write-Host -ForegroundColor Green "Cleared MFA session."
}