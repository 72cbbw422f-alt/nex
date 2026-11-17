# NEXUS — Approved visual direction

## Status

**Approved by the user on 2026-11-18.** The supplied NEXUS concept images are the visual source of truth for the finished product. Do not replace this direction with the earlier lime-green concept or independently redesign the interface. Present major visual changes for approval first.

Reproduce the approved visual language and layouts as closely as practical across iPhone, iPad and Apple TV, adapting composition to each screen rather than shrinking a desktop layout.

## Visual identity

- Premium, cinematic, modern Apple-platform streaming experience.
- Deep navy / near-black surfaces, subtle blue-purple atmosphere and restrained gradients.
- Vivid violet / purple for selected navigation, focus, primary actions, progress and active states.
- Clear, high-contrast SF-style hierarchy; strong cinematic titles and compact but legible metadata.
- Rounded cards, subtle borders and depth; artwork dominates.
- Lime-green as primary accent is superseded by this approved violet direction.
- Use real provider artwork and metadata when connected; concept artwork is illustrative.

## iPhone

- Compact top bar with NEXUS identity and quick actions such as search, casting/connection and notifications.
- Horizontal primary navigation: Hem, Filmer, Serier, Live and Min lista, with clear violet selected state.
- Large cinematic featured title with artwork, key metadata and prominent play action.
- Visible **Live nu** shelf with channel identity/logo, current programme, time range and progress.
- Continue watching cards with episode/movie context and remaining progress.
- Popular/curated title shelves.
- Film/series detail pages with artwork-led header, title, year, rating, runtime/seasons, genres, synopsis and play/list actions.
- Series detail includes season selection and episode rows with thumbnails, duration, watched state and resume state.

## iPad

- Same visual language and content hierarchy, with more room for simultaneous navigation and metadata.
- Do not simply stretch the iPhone layout; use a deliberate multi-column composition where useful.

## Apple TV

- Wide cinematic home hero and large artwork.
- Clear navigation for Hem, Filmer, Serier, Live, Min lista and relevant secondary destinations.
- Prominent Live nu channel row on the home screen.
- Strong violet focus states, generous spacing and large readable typography for ten-foot viewing.
- Remote-friendly focus movement and activation; avoid tiny touch-oriented controls.

## Live TV and EPG

- Live TV is a first-class destination, not just a small homepage widget.
- Home includes a compact Live nu shelf.
- Dedicated Live TV area provides channel groups/categories, favourites, channel logos, now/next programme information and a full programme guide (EPG).
- EPG should be a real timeline/grid with channel rows and programme blocks, current-time indicator, programme details and direct tune action where provider data allows.
- Keep channel browsing and playback fast on Apple TV remote.

## Film and series metadata

- Rich detail pages inspired by the supplied Cinema/Fusion reference.
- Show synopsis, release year/date, runtime, genres, content rating, TMDB rating where available, cast with portraits and roles, director/creator and related titles.
- Expose technical playback information only when known: resolution, HDR/Dolby Vision, audio formats, subtitle availability and source variants.
- Show source availability without exposing sensitive stream URLs.
- Series pages show seasons and detailed episode lists, including episode still, title, overview, runtime, air date and watched/progress state.
- Sections may include Om, Avsnitt/Säsonger, Relaterat and Extra when relevant.

## Player and subtitles

- Player chrome follows the same dark navy and violet visual system.
- Provide playback timeline, seek controls, audio track, subtitle selector, player selection and playback settings.
- Subtitle preferences use ordered language priorities and automatic selection when a good match exists.
- Keep controls restrained and readable over video.

## Shared component principles

Build reusable SwiftUI components and tokens for color, typography, spacing, radii, shadows, focus states, navigation, hero/backdrop, poster tile, horizontal shelf, progress indicator, live channel card, EPG programme block, channel row, metadata chips, cast cards, season selector, episode row, player controls, subtitle picker and source/player selector.

## Acceptance criteria

The user-approved concept images are the visual acceptance reference. Review each platform against them before considering the design shell complete. Differences should be justified by platform ergonomics, accessibility or actual content constraints—not arbitrary redesign.
