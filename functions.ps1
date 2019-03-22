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
 
function Clear-ZScaler {
  $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
  Set-ItemProperty -path $regKey AutoConfigURL -Value ""
  #http://pac.zscalertwo.net/philips.com/global-pac.pac
  Write-Host "ZScaler Proxy Script Cleared" -ForegroundColor Green
}

function touch ($filename) {
  New-Item -ItemType file $filename
}

function tail([String]$filename, [int]$lines = 10) {
  Get-Content $filename -Wait -Tail $lines
}