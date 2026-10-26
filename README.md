# MySearch - SearXNG Desktop Client

**MySearch** is a privacy-friendly desktop search engine client for Linux, powered by self-hosted or public **SearXNG** instances. Built with Flutter, Material 3, and native GTK window integration.

---

## 🚀 Running SearXNG via Docker

To run a local SearXNG search engine instance on Linux:

```bash
docker run -d -p 8080:8080 searxng/searxng
```

Your local SearXNG instance will be available at `http://localhost:8080`.

---

## Features

- **Home Screen**: Centered app layout with a rounded search field, Search button, and search triggers (Enter key or button click).
- **Recent Search History**: Local search history suggestions (last 10 queries) shown when the search field is focused and empty, with a "Clear history" option.
- **Three Search Categories**:
  - **All**: Web search results displaying site hostname, engine source badge (e.g. Google, DuckDuckGo), clickable title, and HTML-stripped text snippet.
  - **News**: News articles displaying source engine, site hostname, and relative published time.
  - **Images**: Responsive thumbnail grid (3–5 columns based on window width). Tapping an image opens a modal dialog with full image preview, title, engine badge, source site, and direct action buttons ("Open page" & "Open image").
- **Lazy Tab Fetching & Caching**: Search results for each tab are fetched only when that tab is opened and cached per query so switching tabs does not trigger redundant network requests.
- **Bookmarks System**: Save any web or news search result by clicking its bookmark icon. Bookmarks are persisted locally as JSON (`shared_preferences`) and managed on the **Bookmarks** screen.
- **Configurable Instance Settings**: Configure any local or public SearXNG instance URL in **Settings** (defaults to `http://localhost:8080`).
- **External Browser Integration**: Clicking results opens links directly in the default Linux web browser (`url_launcher`).
- **Robust Connection Error Handling**: Friendly error messages if the SearXNG Docker container or instance is unreachable, complete with Retry buttons.

---

## Linux Build Dependencies

On **Ubuntu / Debian** systems, install the required build tools and development libraries:

```bash
sudo apt update
sudo apt install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libsecret-1-dev
```

---

## Running and Building

### 1. Fetch Dependencies & Run Tests
```bash
flutter pub get
flutter test
flutter analyze
```

### 2. Run on Linux Desktop
```bash
flutter run -d linux
```

### 3. Build Release Executable
```bash
flutter build linux --release
```
The compiled binary and dependencies will be output to:
`build/linux/x64/release/bundle/`

---

## Project Structure

```
lib/
├── models/
│   ├── search_result.dart       # SearchResult model with HTML stripper & relative time formatter
│   └── image_result.dart        # ImageResult model for SearXNG image results
├── services/
│   ├── searxng_api.dart         # SearXNG GET API client & URL validator
│   └── storage_service.dart     # Storage manager for instance URL, history, & bookmarks
├── providers/
│   └── search_provider.dart     # State management, lazy tab loading, & caching
├── screens/
│   ├── home_screen.dart         # Home screen with search field & history suggestions
│   ├── results_screen.dart      # Results screen with 3 tabs ("All", "News", "Images")
│   ├── bookmarks_screen.dart    # Saved bookmarks management screen
│   └── settings_screen.dart     # SearXNG instance URL configuration & Docker setup help
├── widgets/
│   ├── result_tile.dart         # Web/News result card with engine badge & bookmark button
│   └── image_grid.dart          # Responsive thumbnail grid & preview modal
└── main.dart                    # App entry point (Material 3, System theme)
```
