# Flutter Web Frontend Deployment Guide

This guide covers deploying the Flutter web frontend to production hosting services.

## Prerequisites

- Flutter SDK installed (3.0.0 or higher)
- Node.js and npm (for Firebase CLI)
- Production Nakama server URL (e.g., `https://your-domain.com:7351`)

## Environment Configuration

The frontend requires the Nakama server URL to be configured at build time.

### Setting the Nakama Server URL

The server URL is passed as a Dart define during the build process:

```bash
export NAKAMA_SERVER_URL="https://your-domain.com:7351"
```

Or inline with the build command:

```bash
flutter build web --release --dart-define=NAKAMA_SERVER_URL=https://your-domain.com:7351
```

## Building for Production

### Using the Build Script (Recommended)

1. **Set environment variable**:
   ```bash
   export NAKAMA_SERVER_URL="https://your-domain.com:7351"
   ```

2. **Run build script**:
   ```bash
   cd frontend
   ./build-prod.sh
   ```

The script will:
- Clean previous builds
- Get dependencies
- Build the web app with production optimizations
- Output to `build/web/`

### Manual Build

```bash
cd frontend

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build for web (release mode)
flutter build web \
    --release \
    --dart-define=NAKAMA_SERVER_URL=https://your-domain.com:7351 \
    --web-renderer canvaskit
```

### Build Options

- `--release`: Enables production optimizations (minification, tree-shaking)
- `--dart-define=NAKAMA_SERVER_URL=<url>`: Sets the backend server URL
- `--web-renderer canvaskit`: Uses CanvasKit for better performance (default)
- `--web-renderer html`: Alternative renderer for smaller bundle size

## Deployment Options

### Option 1: Firebase Hosting (Recommended)

Firebase Hosting provides:
- Free SSL/TLS certificates
- Global CDN
- Easy rollbacks
- Custom domain support

#### Setup

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase** (first time only):
   ```bash
   cd frontend
   firebase init hosting
   ```
   
   Configuration:
   - Select or create a Firebase project
   - Public directory: `build/web`
   - Single-page app: `Yes`
   - Automatic builds: `No`

4. **Update `.firebaserc`** with your project ID:
   ```json
   {
     "projects": {
       "default": "your-firebase-project-id"
     }
   }
   ```

#### Deploy

1. **Build the app**:
   ```bash
   export NAKAMA_SERVER_URL="https://your-domain.com:7351"
   ./build-prod.sh
   ```

2. **Deploy to Firebase**:
   ```bash
   firebase deploy --only hosting
   ```

3. **Verify deployment**:
   - Visit the URL provided by Firebase (e.g., `https://your-project.web.app`)
   - Test authentication and matchmaking

#### Custom Domain

1. **Add custom domain in Firebase Console**:
   - Go to Hosting → Add custom domain
   - Follow DNS configuration instructions

2. **Update DNS records**:
   - Add A records or CNAME as instructed
   - Wait for DNS propagation (up to 24 hours)

3. **SSL certificate**:
   - Firebase automatically provisions SSL certificates
   - HTTPS is enforced by default

### Option 2: Vercel

Vercel provides:
- Automatic HTTPS
- Global CDN
- Git integration
- Zero configuration

#### Setup

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel**:
   ```bash
   vercel login
   ```

#### Deploy

1. **Build the app**:
   ```bash
   cd frontend
   export NAKAMA_SERVER_URL="https://your-domain.com:7351"
   ./build-prod.sh
   ```

2. **Deploy to Vercel**:
   ```bash
   cd build/web
   vercel --prod
   ```

3. **Configure environment variable** (via Vercel dashboard):
   - Go to your project settings
   - Navigate to Environment Variables
   - Add: `NAKAMA_SERVER_URL` = `https://your-domain.com:7351`
   - Redeploy for changes to take effect

#### Git Integration (Alternative)

1. **Push to GitHub**:
   ```bash
   git push origin main
   ```

2. **Import project in Vercel**:
   - Go to Vercel dashboard
   - Click "Import Project"
   - Select your repository
   - Configure build settings:
     - Framework Preset: Other
     - Build Command: `cd frontend && flutter build web --release --dart-define=NAKAMA_SERVER_URL=$NAKAMA_SERVER_URL`
     - Output Directory: `frontend/build/web`
   - Add environment variable: `NAKAMA_SERVER_URL`

3. **Automatic deployments**:
   - Vercel will automatically deploy on every push to main

### Option 3: Netlify

1. **Install Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   ```

2. **Build the app**:
   ```bash
   cd frontend
   export NAKAMA_SERVER_URL="https://your-domain.com:7351"
   ./build-prod.sh
   ```

3. **Deploy**:
   ```bash
   cd build/web
   netlify deploy --prod
   ```

### Option 4: Custom Web Server

For deploying to your own web server (Apache, Nginx, etc.):

1. **Build the app**:
   ```bash
   cd frontend
   export NAKAMA_SERVER_URL="https://your-domain.com:7351"
   ./build-prod.sh
   ```

2. **Copy files to web server**:
   ```bash
   # Via SCP
   scp -r build/web/* user@your-server:/var/www/html/
   
   # Or via rsync
   rsync -avz build/web/ user@your-server:/var/www/html/
   ```

3. **Configure web server**:

   **Nginx**:
   ```nginx
   server {
       listen 80;
       server_name your-frontend-domain.com;
       root /var/www/html;
       index index.html;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
       
       # Cache static assets
       location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
           expires 1y;
           add_header Cache-Control "public, immutable";
       }
   }
   ```

   **Apache** (.htaccess):
   ```apache
   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteBase /
       RewriteRule ^index\.html$ - [L]
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteCond %{REQUEST_FILENAME} !-d
       RewriteRule . /index.html [L]
   </IfModule>
   
   # Cache static assets
   <FilesMatch "\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$">
       Header set Cache-Control "max-age=31536000, public, immutable"
   </FilesMatch>
   ```

4. **Enable HTTPS**:
   ```bash
   # Using Certbot
   sudo certbot --nginx -d your-frontend-domain.com
   ```

## Verifying Deployment

### 1. Check HTTPS

```bash
curl -I https://your-frontend-domain.com
# Should return 200 OK with HTTPS
```

### 2. Test Application

1. Open the deployed URL in a browser
2. Check browser console for errors
3. Test authentication flow
4. Test matchmaking
5. Play a complete game
6. Check leaderboard

### 3. Performance Testing

Use Lighthouse (Chrome DevTools):
1. Open DevTools (F12)
2. Go to Lighthouse tab
3. Run audit
4. Target scores:
   - Performance: > 90
   - Accessibility: > 90
   - Best Practices: > 90
   - SEO: > 80

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `NAKAMA_SERVER_URL` | Backend Nakama server URL | `https://api.example.com:7351` |

## Build Output

After a successful build, the `build/web/` directory contains:

```
build/web/
├── index.html              # Main HTML file
├── main.dart.js            # Compiled Dart code
├── flutter.js              # Flutter engine
├── flutter_service_worker.js
├── manifest.json           # PWA manifest
├── assets/                 # App assets
│   ├── fonts/
│   ├── packages/
│   └── AssetManifest.json
├── canvaskit/              # CanvasKit renderer
└── icons/                  # App icons
```

Total size: ~2-3 MB (gzipped)

## Troubleshooting

### Build Fails

**Issue**: `flutter build web` fails

**Solutions**:
1. Update Flutter: `flutter upgrade`
2. Clean build: `flutter clean && flutter pub get`
3. Check Flutter version: `flutter --version` (should be 3.0.0+)

### Can't Connect to Backend

**Issue**: Frontend can't connect to Nakama server

**Solutions**:
1. Verify `NAKAMA_SERVER_URL` is correct
2. Check CORS settings on Nakama (should allow your frontend domain)
3. Verify Nakama server is accessible: `curl https://your-domain.com:7351/`
4. Check browser console for CORS errors
5. Ensure HTTPS is used (mixed content blocked by browsers)

### Large Bundle Size

**Issue**: Build output is too large

**Solutions**:
1. Use `--web-renderer html` instead of `canvaskit` (smaller but less performant)
2. Enable tree-shaking (automatic in release mode)
3. Remove unused dependencies from `pubspec.yaml`
4. Use code splitting (advanced)

### Slow Load Times

**Issue**: App takes too long to load

**Solutions**:
1. Enable CDN caching (automatic with Firebase/Vercel)
2. Use `--web-renderer html` for faster initial load
3. Optimize assets (compress images, use WebP)
4. Enable gzip compression on web server
5. Use a CDN for static assets

### Theme Not Persisting

**Issue**: Theme preference resets on page reload

**Solutions**:
1. Check browser local storage is enabled
2. Verify `shared_preferences` package is configured correctly
3. Check browser console for storage errors

## Continuous Deployment

### GitHub Actions (Firebase)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Build web app
        run: |
          cd frontend
          flutter pub get
          flutter build web --release --dart-define=NAKAMA_SERVER_URL=${{ secrets.NAKAMA_SERVER_URL }}
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-firebase-project-id
```

Add secrets in GitHub repository settings:
- `NAKAMA_SERVER_URL`
- `FIREBASE_SERVICE_ACCOUNT`

## Rollback

### Firebase

```bash
# List previous deployments
firebase hosting:channel:list

# Rollback to previous version
firebase hosting:rollback
```

### Vercel

```bash
# List deployments
vercel ls

# Promote a previous deployment
vercel promote <deployment-url>
```

## Monitoring

### Firebase Hosting

- View analytics in Firebase Console
- Monitor bandwidth usage
- Check error rates

### Vercel

- View analytics in Vercel dashboard
- Monitor performance metrics
- Check deployment logs

### Custom Monitoring

Use Google Analytics or similar:

1. Add tracking code to `web/index.html`
2. Track page views, errors, and user interactions
3. Monitor performance metrics

## Support

For deployment issues:
- Flutter Web: https://docs.flutter.dev/platform-integration/web
- Firebase Hosting: https://firebase.google.com/docs/hosting
- Vercel: https://vercel.com/docs
