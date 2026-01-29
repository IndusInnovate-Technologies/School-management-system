$path = "c:\Users\D-IT\Desktop\sushil code\frontend\apps\parent_main_folder\lib\main.dart"
$lines = Get-Content $path
$newLines = New-Object System.Collections.Generic.List[String]

for ($i = 0; $i -lt $lines.Count; $i++) {
    # Skip lines in range [3638, 4651] (0-indexed indices for lines 3639-4652)
    # 3639: class _TeacherChatScreen ...
    # 4652: (empty line before Group Chat)
    if ($i -ge 3638 -and $i -le 4651) {
        continue
    }
    
    $line = $lines[$i]
    # Replace usage
    # builder: (context) => _TeacherChatScreen(teacher: teacher),
    if ($line -match "_TeacherChatScreen\(") {
         $line = $line -replace "_TeacherChatScreen\(", "TeacherChatScreen("
    }
    $newLines.Add($line)
}

$newLines | Set-Content $path -Encoding UTF8
