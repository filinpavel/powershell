#param ([string] $pc = $( Read-Host "Enter remote target name" ))

Add-Type -AssemblyName System.Windows.Forms 

$file = New-Object System.Windows.Forms.OpenFileDialog
$file.Title = "Open file with list of target hosts"

$file.ShowDialog()
$hostlist = Get-Content $file.FileName

Write-Host " "
Write-Host "Downloading original AV binary..." -ForegroundColor yellow
Write-Host " "
try {
    Invoke-WebRequest -UseBasicParsing -Uri https://devbuilds.s.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe -OutFile c:\temp\kvrt.exe
}
catch {
Write-Host "Download Error" -ForegroundColor Red
}

foreach ($pc in $hostlist) {
Write-Host " "
Write-Host "Copying file to target host..." -ForegroundColor yellow
Write-Host " "
try {
    Copy-Item -Path "c:\temp\kvrt.exe" -Destination "\\$pc\c$\temp" -verbose 
}
catch {
Write-Host "Copy Error" -ForegroundColor Red
}

Invoke-WmiMethod -ComputerName $pc -Path Win32_process -Name Create -ArgumentList {cmd /c c:\temp\KVRT.exe -dontcryptsupportinfo -silent -allvolumes -accepteula -d c:\temp} | Select-Object -Property  ProcessId, ReturnValue

}
