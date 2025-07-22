param (
    [string]$BasePath = "$PSScriptRoot\ShopifyDotNetApp"
)

function Write-Info($msg) {
    Write-Host "==> $msg" -ForegroundColor Cyan
}

Write-Info "Creating base structure at: $BasePath"
New-Item -ItemType Directory -Path $BasePath -Force | Out-Null

# Folder structure
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
    New-Item -ItemType Directory -Path (Join-Path $BasePath $folder) -Force | Out-Null
}

# --------------------- Static files ---------------------
Set-Content "$BasePath\README.md" @"
# Shopify .NET App Shell

This is a reusable shell for embedded Shopify apps built with:

- ASP.NET Core backend (C#)
- React + Polaris frontend (Vite)
- OAuth & App Bridge-ready structure
- Terraform + GitHub Actions deployment support
"@

Set-Content "$BasePath\.gitignore" @"
bin/
obj/
node_modules/
.env
.vscode/
"@

Set-Content "$BasePath\Config\.env.template" @"
SHOPIFY_API_KEY=
SHOPIFY_API_SECRET=
SHOPIFY_SCOPES=read_products,write_discounts
SHOPIFY_APP_URL=https://your-app-url
AZURE_WEBAPP_NAME=
"@

Set-Content "$BasePath\Server\Program.cs" @"
var builder = WebApplication.CreateBuilder(args);

// TODO: Add ShopifyAuthService, Middleware, AppBridge setup

var app = builder.Build();
app.MapGet("/", () => "Shopify .NET App is running");
app.Run();
"@

Set-Content "$BasePath\Server\Controllers\AuthController.cs" @"
// TODO: Handle OAuth Redirect and Token Exchange
"@

Set-Content "$BasePath\Server\Controllers\ProxyController.cs" @"
// TODO: Handle App Proxy requests (HMAC verified)
"@

Set-Content "$BasePath\Server\Services\Auth\ShopifyAuthService.cs" @"
// TODO: Handle auth URL generation, token exchange, session persistence
"@

Set-Content "$BasePath\Server\Services\Shopify\ShopifyClient.cs" @"
// TODO: Create typed client for Shopify GraphQL Admin API
"@

Set-Content "$BasePath\Shared\Shared.csproj" @"
<Project Sdk=""Microsoft.NET.Sdk"">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
"@

# --------------------- GitHub Actions ---------------------
Set-Content "$BasePath\.github\workflows\azure-deploy.yml" @"
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

# --------------------- Terraform ---------------------
Set-Content "$BasePath\infra\main.tf" @"
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

Set-Content "$BasePath\infra\variables.tf" @"
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

Set-Content "$BasePath\infra\outputs.tf" @"
output ""app_service_url"" {
  value = azurerm_app_service.webapp.default_site_hostname
}
"@

Set-Content "$BasePath\infra\README.md" @"
# Terraform Infra for Shopify App

## Usage

1. Fill in variables:

\`\`\`hcl
terraform apply -var=\"app_name=my-shopify-app\" -var=\"resource_group_name=my-rg\"
\`\`\`

2. Deploy with GitHub Actions or manually publish

This sets up:
- Resource Group
- App Service Plan
- Web App (Linux, .NET 8)
"@

# --------------------- AdminUI (React + Polaris) ---------------------
Write-Info "Scaffolding frontend (React + Polaris)"
Push-Location "$BasePath\AdminUI"
npm create vite@latest . -- --template react
npm install @shopify/polaris @shopify/app-bridge-react
Pop-Location

Write-Info "✅ Shopify .NET app shell created with Terraform and CI/CD support."
