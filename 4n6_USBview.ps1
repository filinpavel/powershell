Add-Type -AssemblyName System.Windows.Forms
$file = New-Object System.Windows.Forms.OpenFileDialog
$file.Title = "Open file with list of target host: "
$file.Filter = "All files (*.*)|*.*"
$file.ShowDialog()
$computers = Get-Content $file.FileName
foreach($pc in $computers) {
    Get-WmiObject -ComputerName $pc Win32_USBControllerDevice |ForEach-Object{[wmi]($_.Dependent)} |
     Sort-Object Manufacturer,Description,DeviceID| Format-Table -GroupBy Manufacturer Description,Service,DeviceID
}