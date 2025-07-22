param (
    [Parameter(Mandatory)]
    [string]$NewAppName,

    [string]$DestinationPath = "$PSScriptRoot\.."
)

$SourcePath = $PSScriptRoot
$TargetPath = Join-Path -Path $DestinationPath -ChildPath $NewAppName

function Write-Info($msg) {
    Write-Host "==> $msg" -ForegroundColor Green
}

function ReplaceInFile($file, $oldText, $newText) {
    (Get-Content $file) -replace $oldText, $newText | Set-Content $file
}

# Step 1: Copy the folder
Write-Info "Copying app shell to $TargetPath..."
Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force -Exclude '.git', 'node_modules', 'bin', 'obj'

# Step 2: Rename folder references and content
Write-Info "Replacing identifiers..."
$filesToUpdate = Get-ChildItem -Path $TargetPath -Recurse -Include *.cs,*.csproj,*.json,*.js,*.jsx,*.ts,*.tsx,*.yml,*.md,*.env.template

foreach ($file in $filesToUpdate) {
    ReplaceInFile -file $file.FullName -oldText "ShopifyDotNetApp" -newText $NewAppName
}

# Optional: Re-init Git repo
if (Test-Path "$TargetPath\.git") {
    Write-Info "Removing Git history..."
    Remove-Item -Recurse -Force "$TargetPath\.git"
}

Write-Info "Initializing new Git repo..."
Push-Location $TargetPath
git init
git add .
git commit -m "Initial commit from ShopifyAppShell"
Pop-Location

Write-Info "✅ New Shopify app '$NewAppName' created at: $TargetPath"
