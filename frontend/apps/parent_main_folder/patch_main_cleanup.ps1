$path = "c:\Users\D-IT\Desktop\sushil code\frontend\apps\parent_main_folder\lib\main.dart"
$lines = Get-Content $path
$newLines = New-Object System.Collections.Generic.List[String]

# Target lines to remove (1-based from view):
# 150, 151
# 179, 180, 181, 182

for ($i = 0; $i -lt $lines.Count; $i++) {
    $lineNum = $i + 1
    
    if ($lineNum -eq 150 -or $lineNum -eq 151) {
        continue
    }
    
    if ($lineNum -ge 179 -and $lineNum -le 182) {
        continue
    }
    
    $newLines.Add($lines[$i])
}

$newLines | Set-Content $path -Encoding UTF8
