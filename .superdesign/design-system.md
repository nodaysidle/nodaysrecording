# NoDays Record — design system

## Product context

NoDays Record is a free, open-source macOS desktop app for making polished screen recordings for demos and tutorials. The core loop is: choose a capture source, set a lightweight recording recipe, record with a global shortcut, then refine the take in a friendly local editor and export it. The app should feel calm and precise enough for everyday use, with visible local-first boundaries and no cloud dependency for the main workflow.

## Key surfaces and flows

- **Home / recording tray**: a left navigation rail for Recordings, Templates, and Settings; a prominent recording setup workspace; recent takes with duration, capture mode, and status.
- **Capture setup**: segmented source chooser for Screen, Window, or Area; microphone and system audio toggles; face cam toggle; countdown selector; global shortcut hint; one unmistakable Record action.
- **Recording state**: compact always-on-top tray with elapsed time, pause/resume, stop, and a drawing toggle. The visual language should remain quiet while recording.
- **Editor**: project title and save/share controls, a large video stage, timeline with playhead, zoom/focus markers, cursor controls, background treatments, captions, and a preset picker.
- **Presets**: reusable style recipes for background, cursor, zoom behavior, caption appearance, and framing.

## Visual direction

Use a **Neural Noir** foundation translated into a native macOS utility: deep graphite-black surfaces, restrained glass layers, a fine radial dot grid, warm sand/gold accents, and high contrast text. The result should be cleaner and more practical than a cinematic marketing page: generous negative space, strong hierarchy, minimal chrome, and one primary action per surface. Never use generic blue/purple tech gradients.

### Color tokens

- `canvas`: `#090B0F` — app background.
- `surface`: `rgba(255,255,255,0.045)` — elevated glass panels.
- `surfaceStrong`: `#151820` — solid controls and timeline surfaces.
- `border`: `rgba(255,255,255,0.10)` — quiet separators.
- `borderStrong`: `rgba(255,255,255,0.18)` — active field / focus outline.
- `textPrimary`: `#F7F4EE`.
- `textSecondary`: `#A9A6A0`.
- `textTertiary`: `#73716D`.
- `accent`: `#C9B8A0` — warm light gold.
- `accentStrong`: `#E8D5B7` — primary action / selected state.
- `accentDeep`: `#A78B71` — muted bronze detail.
- `recording`: `#F06B5C` — recording-only signal color.
- `success`: `#9EBFA4`.

### Typography

Use native macOS system typography for legibility and performance: SF Pro Display/Text (SwiftUI `.system` / `.system(.body)`) with regular-to-semibold weights. Display titles can use a restrained serif italic treatment when it helps the product feel authored, but labels and controls remain system sans. Use 10–12 pt uppercase labels with 0.12–0.18 tracking sparingly.

### Shape, spacing, and depth

- Base spacing unit: 4 pt. Common gaps: 8, 12, 16, 24, 32.
- Panel radius: 18–22 pt; compact control radius: 10–12 pt; pills: 999 pt.
- Cards use a 1 pt border and a soft 0 20 60 black shadow at low opacity.
- Prefer one large stage plus supporting panels over many equal cards.
- Use a radial dot grid at 32 pt spacing with white at ~6–8% opacity behind the main workspace, never behind small controls.

### Components

- **Sidebar rail**: 76–88 pt wide, dark glass, logo mark, compact icon + label rows, active row filled with warm gold tint.
- **Primary button**: warm light-gold fill, graphite text, 11–12 pt semibold, 10–12 pt radius, subtle highlight on hover.
- **Secondary button**: transparent or glass fill, quiet border, white text.
- **Source selector**: three equal cards with a simple line icon, title, short descriptor, and a selected gold outline.
- **Toggle**: small rounded switch; gold track for enabled, muted graphite for disabled.
- **Timeline**: dark band with a copper playhead, small markers, and a high-contrast active clip.
- **Recording tray**: compact horizontal glass capsule, recording signal dot, elapsed time, pause button, stop button, and optional annotation affordance.

### Motion

Use short ease-out transitions (160–220 ms) for hover, selection, and tray expansion. Use a slow breathing glow only for the live recording signal. Avoid perpetual decorative animation in the editor.

## Native implementation constraints

- Swift 6 + SwiftUI + AppKit bridges where required.
- Local-first: captured media, presets, captions, and project metadata stay on disk unless the user explicitly exports or shares.
- Capture architecture should be ready for ScreenCaptureKit, AVFoundation audio, AVCaptureSession camera, and a native global hotkey bridge.
- Caption architecture should allow a local speech-to-text engine later without putting network APIs in the core UI.
- Never use preview media, fake recordings, or simulated completed timeline state. The editor renders only a real movie selected from the local library; before the first take, show an explicit empty state.

## Accessibility and privacy

Every toolbar icon needs a text label. Recording, microphone, system audio, and camera states must be visible in text as well as color. Explain permissions before requesting them. Keep camera/microphone/captured content local by default and expose a clear settings surface for permissions and storage location.
