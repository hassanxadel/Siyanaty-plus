# PowerShell script to fix all instances of Expanded(child: Expanded(child: SizedBox pattern
# This pattern causes layout errors when used inside SingleChildScrollView

Write-Host "Starting to fix Expanded(child: Expanded(child: SizedBox patterns..." -ForegroundColor Green

# Get all Dart files in lib folder
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"

$totalFiles = 0
$totalReplacements = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileModified = $false
    
    # Replace all instances of Expanded(child: Expanded(child: SizedBox(... ))) with just SizedBox(... )
    # Handle const variants
    $pattern1 = 'const\s+Expanded\s*\(\s*child:\s*Expanded\s*\(\s*child:\s*SizedBox\s*\(\s*([^)]+)\s*\)\s*\)\s*\)'
    if ($content -match $pattern1) {
        $content = $content -creplace $pattern1, 'const SizedBox($1)'
        $fileModified = $true
    }
    
    # Handle non-const variants
    $pattern2 = '(?<!const\s)Expanded\s*\(\s*child:\s*Expanded\s*\(\s*child:\s*SizedBox\s*\(\s*([^)]+)\s*\)\s*\)\s*\)'
    if ($content -match $pattern2) {
        $content = $content -creplace $pattern2, 'SizedBox($1)'
        $fileModified = $true
    }
    
    if ($fileModified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $matches1 = ([regex]::Matches($originalContent, $pattern1)).Count
        $matches2 = ([regex]::Matches($originalContent, $pattern2)).Count
        $matches = $matches1 + $matches2
        $totalReplacements += $matches
        $totalFiles++
        Write-Host "Fixed $matches instance(s) in: $($file.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "`nTotal files modified: $totalFiles" -ForegroundColor Green
Write-Host "Total replacements made: $totalReplacements" -ForegroundColor Green
Write-Host "`nNote: You may need to adjust some specific cases manually." -ForegroundColor Cyan
Write-Host "Specifically, check any locations where Expanded was intentionally used for flexible layout." -ForegroundColor Cyan
