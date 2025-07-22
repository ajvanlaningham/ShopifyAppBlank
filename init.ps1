param (
    [Parameter(Mandatory)]
    [string]$NewAppName,

    [string]$DestinationPath = "$PSScriptRoot\.."
)

function Write-Info($msg) {
    Write-Host "==> $msg" -ForegroundColor Green
}

function ReplaceInFile($file, $oldText, $newText) {
    (Get-Content $file) -replace $oldText, $newText | Set-Content $file
}

$tempShellPath = Join-Path $env:TEMP "ShopifyAppShell_$(Get-Random)"
$targetAppPath = Join-Path $DestinationPath $NewAppName

# === STEP 1: Scaffold a fresh shell ===
Write-Info "Scaffolding shell in temp path: $tempShellPath"
New-Item -ItemType Directory -Path $tempShellPath -Force | Out-Null

$folders = @(
    "Server/Controllers",
    "Server/Services/Auth",
    "Server/Services/Shopify",
    "Server/Middleware",
    "Server/Models",
    "AdminUI",
    "Shared",
    "Config",
    ".github/workflows",
    "infra"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path (Join-Path $tempShellPath $folder) -Force | Out-Null
}

# --- Static files ---
Set-Content "$tempShellPath\README.md" @"
# ShopifyDotNetApp

A reusable shell for embedded Shopify apps built in .NET + React.
"@

Set-Content "$tempShellPath\.gitignore" @"
bin/
obj/
node_modules/
.env
.vscode/
"@

Set-Content "$tempShellPath\Config\.env.template" @"
SHOPIFY_API_KEY=
SHOPIFY_API_SECRET=
SHOPIFY_SCOPES=read_products,write_discounts
SHOPIFY_APP_URL=https://your-app-url
AZURE_WEBAPP_NAME=
"@

Set-Content "$tempShellPath\Server\Program.cs" @"
var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();
app.MapGet("/", () => "Shopify .NET App is running");
app.Run();
"@

Set-Content "$tempShellPath\Server\Controllers\AuthController.cs" @"
// TODO: Handle OAuth Redirect and Token Exchange
"@

Set-Content "$tempShellPath\Server\Controllers\ProxyController.cs" @"
// TODO: Handle App Proxy requests (HMAC verified)
"@

Set-Content "$tempShellPath\Server\Services\Auth\ShopifyAuthService.cs" @"
// TODO: Handle auth URL generation, token exchange, session persistence
"@

Set-Content "$tempShellPath\Server\Services\Shopify\ShopifyClient.cs" @"
// TODO: Create typed client for Shopify GraphQL Admin API
"@

Set-Content "$tempShellPath\Shared\Shared.csproj" @"
<Project Sdk=""Microsoft.NET.Sdk"">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
"@

# --- GitHub Actions ---
Set-Content "$tempShellPath\.github\workflows\azure-deploy.yml" @"
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'

      - name: Build
        run: dotnet build ./Server/Server.csproj --configuration Release

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: \${{ secrets.AZURE_WEBAPP_NAME }}
          publish-profile: \${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: ./Server/bin/Release/net8.0/publish/
"@

# --- Terraform ---
Set-Content "$tempShellPath\infra\main.tf" @"
provider ""azurerm"" {
  features {}
}

resource ""azurerm_resource_group"" ""app"" {
  name     = var.resource_group_name
  location = var.location
}

resource ""azurerm_app_service_plan"" ""plan"" {
  name                = ""\${var.app_service_plan}""
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  kind                = ""Linux""
  reserved            = true
  sku {
    tier = ""Basic""
    size = ""B1""
  }
}

resource ""azurerm_app_service"" ""webapp"" {
  name                = var.app_name
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = ""DOTNETCORE|8.0""
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}
"@

Set-Content "$tempShellPath\infra\variables.tf" @"
variable ""resource_group_name"" {
  type        = string
  description = ""Azure Resource Group Name""
}

variable ""location"" {
  type        = string
  default     = ""East US""
}

variable ""app_name"" {
  type        = string
}

variable ""app_service_plan"" {
  type        = string
}
"@

Set-Content "$tempShellPath\infra\outputs.tf" @"
output ""app_service_url"" {
  value = azurerm_app_service.webapp.default_site_hostname
}
"@

Set-Content "$tempShellPath\infra\README.md" @"
# Terraform Infra for Shopify App

\`\`\`sh
terraform apply -var=\"app_name=my-shopify-app\" -var=\"resource_group_name=my-rg\"
\`\`\`
"@

# --- AdminUI scaffold (React + Polaris) ---
Write-Info "Scaffolding AdminUI (Vite + Polaris)..."
Push-Location "$tempShellPath\AdminUI"
npm create vite@latest . -- --template react
npm install @shopify/polaris @shopify/app-bridge-react
Pop-Location

# === STEP 2: Copy scaffold to real app folder ===
Write-Info "Copying scaffold to $targetAppPath"
robocopy $tempShellPath $targetAppPath /E /NFL /NDL /NJH /NJS /NC | Out-Null

# === STEP 3: Replace default name with new app name ===
Write-Info "Replacing identifiers..."
$filesToUpdate = Get-ChildItem -Path $targetAppPath -Recurse -Include *.cs,*.csproj,*.json,*.js,*.jsx,*.ts,*.tsx,*.yml,*.md,*.env.template -File

foreach ($file in $filesToUpdate) {
    ReplaceInFile -file $file.FullName -oldText "ShopifyDotNetApp" -newText $NewAppName
}

# === STEP 4: Init Git ===
Write-Info "Initializing new Git repo..."
Push-Location $targetAppPath
git init
git add .
git commit -m "Initial commit from generated scaffold"
Pop-Location

# === Cleanup ===
Remove-Item -Recurse -Force $tempShellPath

Write-Info "✅ New app '$NewAppName' created at: $targetAppPath"
