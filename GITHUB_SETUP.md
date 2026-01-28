# GitHub Setup Guide for dia_plus

Follow these steps to set up GitHub for your Flutter project.

## Step 1: Install Git (if not already installed)

1. Download Git for Windows from: https://git-scm.com/download/win
2. Run the installer and follow the installation wizard
3. Use default settings (recommended)
4. After installation, restart your terminal/IDE

## Step 2: Configure Git (First Time Setup)

Open PowerShell or Command Prompt and run:

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

Replace with your actual name and email address.

## Step 3: Initialize Git Repository

Navigate to your project directory and initialize git:

```powershell
cd c:\developer\projects\dia_plus
git init
```

## Step 4: Stage and Commit Your Files

```powershell
git add .
git commit -m "Initial commit"
```

## Step 5: Create a GitHub Repository

1. Go to https://github.com and sign in (or create an account)
2. Click the "+" icon in the top right corner
3. Select "New repository"
4. Name it `dia_plus` (or any name you prefer)
5. Choose Public or Private
6. **DO NOT** initialize with README, .gitignore, or license (since you already have these)
7. Click "Create repository"

## Step 6: Connect Your Local Repository to GitHub

After creating the repository, GitHub will show you commands. Use these:

```powershell
git remote add origin https://github.com/YOUR_USERNAME/dia_plus.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

## Step 7: Authentication

If prompted for credentials:
- **Username**: Your GitHub username
- **Password**: Use a Personal Access Token (not your GitHub password)
  - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
  - Generate a new token with `repo` permissions
  - Copy and use this token as your password

## Alternative: Using GitHub CLI (gh)

If you prefer using GitHub CLI:

1. Install GitHub CLI: https://cli.github.com/
2. Authenticate: `gh auth login`
3. Create and push: `gh repo create dia_plus --public --source=. --remote=origin --push`

## Troubleshooting

- **Git not found**: Make sure Git is installed and added to your PATH
- **Authentication failed**: Use a Personal Access Token instead of password
- **Repository already exists**: Change the repository name or delete the existing one on GitHub

## Next Steps

After setup, you can:
- Make changes to your code
- Commit changes: `git add .` then `git commit -m "Your message"`
- Push changes: `git push`
- Pull changes: `git pull`
