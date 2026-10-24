Get-WmiObject Win32_Process -Filter "name='dart.exe'" | ForEach-Object {
    [PSCustomObject]@{
        Id = $_.ProcessId
        ParentId = $_.ParentProcessId
        CommandLine = $_.CommandLine
    }
} | Format-List
