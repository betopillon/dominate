# Legal Documents for Dominate App

This folder contains all the legal documents required for publishing Dominate on Google Play Store and Apple App Store.

## Files Created

1. **privacy_policy.md** - Privacy Policy compliant with app store requirements
2. **terms_of_service.md** - Terms of Service for app usage
3. **data_collection.md** - Detailed data collection disclosure
4. **index.html** - Web landing page for hosting documents
5. **README.md** - This setup guide

## Setting Up GitHub Pages (Step-by-Step)

### 1. Create GitHub Repository
1. Go to [GitHub.com](https://github.com) and sign in
2. Click "New Repository" (green button)
3. Repository name: `dominate-legal` (or any name you prefer)
4. Make it **Public** (required for free GitHub Pages)
5. Check "Add a README file"
6. Click "Create repository"

### 2. Upload Legal Documents
1. In your new repository, click "Add file" → "Upload files"
2. Upload these files from the `legal_docs` folder:
   - `index.html`
   - `privacy_policy.md` (rename to `privacy_policy.html`)
   - `terms_of_service.md` (rename to `terms_of_service.html`)
   - `data_collection.md` (rename to `data_collection.html`)
3. Write commit message: "Add legal documents for Dominate app"
4. Click "Commit changes"

### 3. Enable GitHub Pages
1. Go to repository "Settings" tab
2. Scroll down to "Pages" section (left sidebar)
3. Under "Source", select "Deploy from a branch"
4. Choose "main" branch and "/ (root)"
5. Click "Save"

### 4. Get Your URLs
After 5-10 minutes, your documents will be available at:
- **Main page**: `https://[USERNAME].github.io/dominate-legal/`
- **Privacy Policy**: `https://[USERNAME].github.io/dominate-legal/privacy_policy.html`
- **Terms of Service**: `https://[USERNAME].github.io/dominate-legal/terms_of_service.html`
- **Data Collection**: `https://[USERNAME].github.io/dominate-legal/data_collection.html`

Replace `[USERNAME]` with your GitHub username.

## Converting Markdown to HTML

The `.md` files need to be converted to `.html` for web hosting. You can:

### Option A: Rename and Upload as HTML
1. Open each `.md` file in a text editor
2. Copy the content
3. Create new `.html` files with this structure:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Document Title</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2, h3 { color: #333; }
    </style>
</head>
<body>
    <!-- Paste your markdown content here, converting # to <h1>, ## to <h2>, etc. -->
</body>
</html>
```

### Option B: Use GitHub's Automatic Conversion
1. Upload `.md` files as-is
2. GitHub Pages will automatically convert them to HTML
3. Access them with `.html` extension in the URL

## Before Publishing Your App

1. **Update dates**: Replace `[DATE YOU PUBLISH]` with actual publication date
2. **Review content**: Make sure all information is accurate for your app
3. **Test links**: Verify all URLs work correctly
4. **Add to app**: Include these URLs in your app store listings

## App Store Requirements

### Google Play Store
- Add Privacy Policy URL in Play Console → App content → Privacy Policy
- Complete Data Safety section using `data_collection.md` as reference

### Apple App Store
- Add Privacy Policy URL in App Store Connect → App Information
- Complete App Privacy section using `data_collection.md` as reference

## Contact Information

All documents reference:
- **Developer**: BetoGames
- **Contact Email**: pillonnnnn@gmail.com

Update these if needed before publishing.

---

**Next Steps After Setup:**
1. Get your GitHub Pages URLs
2. Update the publication plan with these URLs
3. Set up Google Play Console and Apple Developer accounts
4. Complete app store submissions with legal document links