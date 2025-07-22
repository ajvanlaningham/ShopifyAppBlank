# ShopifyAppBlank

A reusable shell for building embedded Shopify apps using **.NET (C#)** and **React + Polaris**.  
This project provides the minimal structure needed to get started with custom apps, including OAuth, App Bridge-ready frontend, and optional Terraform deployment.

---

## Getting Started

### 1. Clone this repository into an empty folder

```bash
git clone https://github.com/ajvanlaningham/ShopifyAppBlank.git
cd ShopifyAppBlank
```

### 2. Create a new app from this shell

```bash
.\init.ps1 -NewAppName "MyShopifyApp"
```

This will:
1. Copy the shell to a new folder named MyShopifyApp
2. Rename internal identifiers
3. Initialize a new Git repo

### What's included

ShopifyAppBlank/
├── AdminUI/         # Vite + React + Polaris frontend
├── Server/          # ASP.NET Core backend with stubs for OAuth and Proxy
├── Shared/          # .NET class library for shared logic
├── infra/           # Terraform templates for Azure deployment
├── .github/         # GitHub Actions CI/CD workflow
├── Config/          # .env.template and config placeholders
├── init.ps1         # Script to instantiate new apps

### Requirements

- .NET 8 SDK
- Node.js + npm
- PowerShell (to run scripts)
- Git

### After Cloning

To start working on your own app:

- Run init.ps1 to create your real app folder.
- Follow Shopify's OAuth and App Bridge setup documentation.
- Add logic as needed (pricing, tagging, custom flows, etc.).
- Use Terraform (infra/) or GitHub Actions (.github/workflows/) to deploy.

### 🛠️ Customize Me!

This shell is meant to be extended. Add your own:

- OAuth token storage (SQL, blob, etc.)
- Webhook handlers
- Pricing or tagging logic
- Admin UI components (e.g. Polaris forms)

### Testing Your Shell

Once you've generated your new app, navigate into it:
```bash
cd ../MyShopifyApp
dotnet build
npm install --prefix ./AdminUI
```

### License
MIT – use, modify, and ship freely.