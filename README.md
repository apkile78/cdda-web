# CDDA WebAssembly Build

This repository contains the GitHub Actions workflow and scripts to build Cataclysm: Dark Days Ahead (CDDA) as a WebAssembly application for the Ito (stable) release.

## 📋 Overview

This project automatically builds CDDA WebAssembly using Emscripten via GitHub Actions and deploys it to GitHub Pages. The build includes:

- **Tiles support**: Full graphical interface
- **Sound support**: Audio playback enabled
- **English-only**: No localization (smaller build size)
- **Release build**: Optimized production build
- **Emscripten 3.1.58**: Pinned version for consistency

## 🚀 Quick Start

### 1. Enable GitHub Pages

1. Go to your repository's **Settings** → **Pages**
2. Set **Source** to **Deploy from a branch**
3. Select **gh-pages** branch and **/ (root)** directory
4. Click **Save**

### 2. Trigger a Build

There are two ways to trigger a build:

#### Option A: Using Tags (Recommended)
```bash
# Create and push a tag to trigger the workflow
git tag cdda-0.I-2026-06-06
git push origin cdda-0.I-2026-06-06
```

#### Option B: Manual Workflow Dispatch
1. Go to **Actions** tab in your repository
2. Select **CDDA WebAssembly Build** workflow
3. Click **Run workflow**
4. Enter the release tag (e.g., `cdda-0.I-2026-06-06` or `latest`)

### 3. Access Your Build

Once the workflow completes, your CDDA WebAssembly build will be available at:
```
https://<username>.github.io/<repository-name>/
```

## 📁 Project Structure

```
cdda-web/
├── .github/
│   └── workflows/
│       └── cdda-web.yml          # GitHub Actions workflow
├── scripts/
│   ├── fetch_release.sh          # Downloads CDDA release tarball
│   ├── build_web.sh              # Emscripten compilation script
│   └── package_web.sh            # Packages output for GitHub Pages
├── index.html                    # Custom web launcher
└── README.md                     # This file
```

## 🔧 Configuration

### Build Settings

The workflow uses the following build settings (configurable in `.github/workflows/cdda-web.yml`):

```yaml
env:
  EMSCRIPTEN_VERSION: '3.1.58'    # Pinned Emscripten version
  BUILD_TYPE: 'Release'           # Release or Debug
  BUILD_TILES: 'true'             # Tiles or Terminal-only
  BUILD_SOUND: 'true'             # Sound support
  BUILD_LOCALIZATION: 'false'     # Localization support
```

### Modifying Build Options

To change build options, edit the environment variables in `.github/workflows/cdda-web.yml`:

- **Disable Tiles**: Set `BUILD_TILES: 'false'`
- **Disable Sound**: Set `BUILD_SOUND: 'false'`
- **Enable Localization**: Set `BUILD_LOCALIZATION: 'true'`
- **Debug Build**: Set `BUILD_TYPE: 'Debug'`

## 🔄 Updating to Future Releases

### Option 1: Latest Stable Release
Use the automatic latest detection:
```bash
git tag cdda-latest-$(date +%Y%m%d)
git push origin cdda-latest-$(date +%Y%m%d)
```

### Option 2: Specific Release
Tag with the specific release version:
```bash
git tag cdda-0.I-2026-06-06
git push origin cdda-0.I-2026-06-06
```

### Option 3: Manual Dispatch
1. Go to **Actions** → **CDDA WebAssembly Build**
2. Click **Run workflow**
3. Enter the specific tag (e.g., `cdda-0.I-2026-06-06`)

## 🛠️ Local Development

### Prerequisites
- Emscripten SDK
- CMake
- Build tools (make, gcc, etc.)

### Local Build Script
```bash
# Install Emscripten
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.58
./emsdk activate 3.1.58
source emsdk_env.sh

# Run build scripts
cd cdda-web
chmod +x scripts/*.sh
./scripts/fetch_release.sh "cdda-0.I-2026-06-06"
./scripts/build_web.sh
./scripts/package_web.sh
```

## 📊 Build Artifacts

Each build produces:
- `index.html` - Web launcher
- `cataclysm-tiles.js` - JavaScript glue code
- `cataclysm-tiles.wasm` - WebAssembly binary
- `cataclysm-tiles.data` - Game assets
- `cataclysm-tiles.data.js` - Asset loader
- `data/` - Game data directory
- `lang/` - Language files (if localization enabled)

Build artifacts are available for download from the GitHub Actions run page for 30 days.

## 🐛 Troubleshooting

### Build Fails

1. **Check the workflow logs** in the Actions tab
2. **Verify the release tag exists** in the CleverRaven/cataclysm-dda repository
3. **Check Emscripten version compatibility** if you modify the version
4. **Ensure you have sufficient GitHub Actions minutes**

### Deployment Fails

1. **Verify GitHub Pages is enabled** in repository settings
2. **Check the gh-pages branch** exists and is not protected
3. **Ensure the workflow has write permissions** to the repository

### Game Won't Load

1. **Check browser console** for JavaScript errors
2. **Verify WebAssembly is supported** in your browser
3. **Check that all files are present** in the deployment
4. **Try clearing browser cache**

## 📝 Workflow Details

### Caching

The workflow uses two cache layers:
1. **Emscripten cache**: Caches the Emscripten SDK installation
2. **Build cache**: Caches CDDA source and build artifacts

### Triggers

- **Tag pushes**: Automatically triggered when tags matching `cdda-*` are pushed
- **Manual dispatch**: Can be triggered manually via GitHub Actions UI

### Deployment

- **Target**: `gh-pages` branch
- **Method**: `peaceiris/actions-gh-pages@v3`
- **Settings**: Force orphan branch (clean history)

## 🔐 Permissions

The workflow requires the following GitHub token permissions:
- `contents: write` - For deployment to gh-pages branch
- `actions: write` - For workflow dispatch

These are automatically provided via `secrets.GITHUB_TOKEN`.

## 📄 License

This build configuration is provided as-is. Cataclysm: Dark Days Ahead is licensed under the CC BY-SA 3.0 license. See the official CDDA repository for details.

## 🤝 Contributing

To contribute improvements to this build system:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the workflow
5. Submit a pull request

## 📞 Support

For issues with:
- **This build system**: Open an issue in this repository
- **CDDA itself**: Visit the official CDDA repository or forums
- **Emscripten**: Check Emscripten documentation

## 🌐 Links

- [CDDA Official Repository](https://github.com/CleverRaven/cataclysm-dda)
- [Emscripten Documentation](https://emscripten.org/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)

---

**Generated with [Devin](https://devin.ai)**