# AGENTS.md

## 1. Project Identity

### Official Name

- **Korean name:** 사상
- **English name:** Sasang
- **Repository / code name:** `sasang`

`Sasang` is the official English project name and must be used consistently in source code,
repository naming, package naming, environment configuration, documentation, CI/CD resources,
and backend service identifiers.

The Korean display name `사상` may be used in user-facing Korean UI and marketing copy.

Preferred naming examples:

```text
Repository: sasang
Mobile app: Sasang
Korean app display name: 사상
Backend service: sasang-backend
Shared package scope: @sasang/*
```

Avoid introducing alternative project names, abbreviations, or temporary branding into production code.

---

## 3. Project Overview

Sasang is a personal travel map application where users can attach photos to visited regions.

The core experience is not a conventional navigation map.  
Administrative boundaries are rendered as vector polygons, and user-selected photos are clipped inside those region boundaries.

Two map modes are supported:

- **Korea Map**
  - Region unit: 시 / 군 / 구
  - Administrative boundary based rendering
- **World Map**
  - Region unit: Country
  - Country boundary based rendering

The UI should remain minimal, clean, and photo-centric.

Primary technical goals:

1. Render administrative boundaries efficiently.
2. Allow users to select a region.
3. Attach one or more photos to a visited region.
4. Clip a selected photo inside the region polygon.
5. Allow photo position / scale adjustment inside the polygon.
6. Persist visit, photo, and crop metadata.
7. Keep map rendering independent from backend implementation.

---

# 3. Monorepo Structure

Use the following repository structure.

Recommended repository name:

```text
sasang
```

Repository layout:

```text
/
├─ app/                      # React Native mobile application
│  ├─ src/
│  │  ├─ app/
│  │  ├─ components/
│  │  ├─ features/
│  │  ├─ screens/
│  │  ├─ hooks/
│  │  ├─ services/
│  │  ├─ store/
│  │  ├─ types/
│  │  ├─ utils/
│  │  └─ assets/
│  │     └─ maps/
│  │        ├─ korea/
│  │        └─ world/
│  ├─ app.json
│  ├─ package.json
│  └─ tsconfig.json
│
├─ backend/                  # Backend API server
│  ├─ src/
│  │  ├─ app/
│  │  ├─ modules/
│  │  ├─ lib/
│  │  ├─ repositories/
│  │  ├─ services/
│  │  ├─ types/
│  │  └─ utils/
│  ├─ prisma/
│  │  └─ schema.prisma
│  ├─ package.json
│  └─ tsconfig.json
│
├─ packages/
│  └─ shared/                # Shared DTOs, schemas and constants
│
├─ scripts/
│  └─ map-data/              # GeoJSON/SHP preprocessing scripts
│
├─ docs/
│
├─ package.json
├─ pnpm-workspace.yaml
├─ turbo.json
└─ AGENTS.md
```

Do not mix mobile UI code with backend business logic.

`app/` and `backend/` must be independently runnable and independently testable.

Recommended workspace package names:

```json
{
  "root": "sasang",
  "app": "@sasang/app",
  "backend": "@sasang/backend",
  "shared": "@sasang/shared"
}
```

Use the `@sasang/*` scope for internal workspace packages where package scopes are appropriate.

---

# 4. Default Technology Stack

Unless a task explicitly requires otherwise, use the following stack.

## Mobile

- React Native
- Expo
- TypeScript
- Expo Router
- react-native-svg
- react-native-gesture-handler
- react-native-reanimated
- expo-image
- expo-image-picker
- TanStack Query
- Zustand for small client-side state

Avoid introducing large state-management libraries unless required.

## Backend

Use:

- Next.js
- TypeScript
- App Router
- Route Handlers for HTTP APIs
- PostgreSQL
- Prisma ORM
- Zod for runtime validation

The backend is API-oriented.

Do not build backend business logic directly inside UI pages or React Server Components.

If a future migration to Spring Boot is required, the API contract and database model should remain reusable.

## Storage

Store user-uploaded images in object storage.

Preferred:

- AWS S3
- Cloudflare R2

Do not store image binary data directly in PostgreSQL.

The database should store object keys, URLs, metadata, and crop information.

---

# 5. Core Architecture Principle

The application is based on:

```text
Administrative boundary
        ↓
GeoJSON / vector polygon
        ↓
SVG Path
        ↓
Photo clipping
        ↓
Interactive travel map
```

Do NOT create separate PNG/JPG files for every 시/군/구 or country.

Administrative regions must be represented as vector geometry.

For the mobile application, preprocess raw map data into lightweight application assets.

Example:

```json
{
  "code": "11680",
  "name": "강남구",
  "type": "KOREA_SIGUNGU",
  "path": "M 123 412 L 125 417 ... Z"
}
```

The production app should not repeatedly parse large raw SHP files or unnecessarily detailed GeoJSON at runtime.

---

# 6. Map Data

## Korea

Administrative unit:

```text
시 / 군 / 구
```

Each region must have a stable code.

Prefer official administrative codes rather than using region names as identifiers.

Example:

```ts
type KoreaRegion = {
  code: string;
  name: string;
  provinceCode: string;
  provinceName: string;
  path: string;
};
```

Do not use:

```ts
regionId = "강남구";
```

as the primary identity.

Use:

```ts
regionCode = "11680";
```

instead.

## World

Country identity should preferably use ISO country codes.

Example:

```ts
type WorldRegion = {
  code: string;       // e.g. KR, JP, US
  name: string;
  path: string;
};
```

## Versioning

Administrative boundaries change over time.

Map data must therefore support a version.

Example:

```ts
type MapMetadata = {
  version: string;
  generatedAt: string;
  source: string;
};
```

Do not silently replace administrative geometry without updating the map data version.

---

# 7. Map Preprocessing

Raw map data should be processed outside the mobile runtime.

Use scripts under:

```text
scripts/map-data/
```

Expected pipeline:

```text
SHP / GeoJSON
      ↓
coordinate normalization
      ↓
geometry simplification
      ↓
Polygon / MultiPolygon normalization
      ↓
SVG path generation
      ↓
mobile asset generation
```

Map preprocessing code must be deterministic.

Given the same source data and options, it should produce the same output.

Do not manually edit generated SVG paths unless absolutely necessary.

If generated files are modified manually, document the reason.

---

# 8. Map Rendering

The primary rendering technology is:

```text
react-native-svg
```

Each administrative region should be represented with an SVG `Path`.

Example conceptual structure:

```tsx
<Svg>
  <Defs>
    <ClipPath id={region.code}>
      <Path d={region.path} />
    </ClipPath>
  </Defs>

  <Image
    href={photoUrl}
    clipPath={`url(#${region.code})`}
  />

  <Path
    d={region.path}
    fill="transparent"
    strokeWidth={1}
  />
</Svg>
```

The exact implementation may differ for performance reasons.

The rendered region should support:

- default state
- visited state
- selected state
- photo-filled state
- pressed state

Do not introduce Google Maps, Mapbox, or another map SDK merely to draw administrative areas.

Use an actual map SDK only when the feature requires capabilities such as:

- geographic navigation
- roads
- POIs
- GPS map positioning
- tile maps
- real-world basemap interaction

---

# 9. Region Photo Model

A photo assigned to a region needs more information than a URL.

At minimum store:

```ts
type RegionPhoto = {
  id: string;
  regionCode: string;
  photoUrl: string;
  thumbnailUrl?: string;

  scale: number;
  offsetX: number;
  offsetY: number;

  createdAt: string;
};
```

This metadata is required because users need to reposition and scale an image inside irregular polygon boundaries.

Do not permanently crop the original photo merely to create the map appearance.

Prefer storing:

```text
original photo
+
crop transform metadata
```

This allows the user to adjust the composition later.

---

# 10. Photo Editing Interaction

Photo placement should behave similarly to profile-image cropping.

Required interactions:

- pinch to zoom
- drag to reposition
- reset
- save

The final region appearance is determined by:

```text
photo
+
scale
+
offsetX
+
offsetY
+
region polygon
```

Keep the source photo unchanged.

The map screen should use an optimized thumbnail or cached image whenever possible.

---

# 11. App Feature Organization

Prefer feature-oriented organization.

Example:

```text
app/src/features/

├─ map/
│  ├─ components/
│  ├─ hooks/
│  ├─ models/
│  ├─ services/
│  └─ utils/
│
├─ visits/
│
├─ photos/
│
├─ auth/
│
└─ profile/
```

Avoid large generic directories containing unrelated components.

For example, prefer:

```text
features/map/components/RegionPath.tsx
```

over:

```text
components/RegionPath.tsx
```

when the component is specific to the map domain.

---

# 12. Recommended App Screens

Initial screens:

```text
Home / Map
├─ Korea
└─ World

Region Detail

Add Visit

Photo Picker

Photo Position Editor

Visit List

Profile / Settings
```

For the MVP, prioritize:

1. Korea / World tab
2. Polygon rendering
3. Region selection
4. Photo selection
5. Photo clipping
6. Photo transform editing
7. Visit persistence

Authentication, social features, complex statistics, and recommendations are secondary.

---

# 13. UI Guidelines

The visual direction is:

- clean
- minimal
- content-first
- photo-centric
- modern iOS-like spacing
- restrained use of decoration

Avoid:

- excessive gradients
- large colored cards
- excessive shadows
- unnecessary borders
- visually heavy navigation
- decorative elements that compete with the map

Prefer:

- white or neutral surfaces
- clear typography hierarchy
- subtle separators
- generous spacing
- bottom sheets for contextual actions
- smooth transitions
- large touch targets

The map itself should remain the visual focus of the home screen.

## Sasang Branding

User-facing naming should follow:

```text
Korean locale: 사상
English / international locale: Sasang
```

Do not translate the product name into another arbitrary English label such as `Travel Map`,
`My Map`, or `Photo Map` in navigation titles, app metadata, or documentation unless it is
descriptive copy rather than the product name.

Examples:

```text
사상
나의 여행을 지도에 남기다

Sasang
Map your travels through photos
```

Taglines are optional and must not replace the official product name.

Do not copy another application's exact visual assets or proprietary design.

Reference other apps only for interaction principles and overall simplicity.

---

# 14. Backend Domain Model

Recommended core entities:

```text
User
Region
Visit
Photo
```

Conceptual relationships:

```text
User
  │
  └── Visit
        │
        ├── Region
        │
        └── Photo
```

A possible schema:

```text
User
----
id
email
nickname
createdAt


Region
------
id
code
name
countryCode
type
mapVersion


Visit
-----
id
userId
regionId
visitedAt
memo
createdAt
updatedAt


Photo
-----
id
visitId
storageKey
url
thumbnailUrl
scale
offsetX
offsetY
width
height
createdAt
```

Possible region types:

```ts
enum RegionType {
  KOREA_SIGUNGU = "KOREA_SIGUNGU",
  WORLD_COUNTRY = "WORLD_COUNTRY",
}
```

---

# 15. API Design

All public API endpoints should be versioned.

Use:

```text
/api/v1/
```

Example endpoints:

```text
GET    /api/v1/regions
GET    /api/v1/regions/:code

GET    /api/v1/visits
POST   /api/v1/visits
GET    /api/v1/visits/:id
PATCH  /api/v1/visits/:id
DELETE /api/v1/visits/:id

POST   /api/v1/photos/upload-url
POST   /api/v1/photos
PATCH  /api/v1/photos/:id
DELETE /api/v1/photos/:id
```

Prefer direct-to-object-storage uploads using signed URLs.

Recommended upload flow:

```text
App
 ↓
request signed upload URL
 ↓
Backend
 ↓
signed URL
 ↓
App
 ↓
S3 / R2
 ↓
upload complete
 ↓
Backend metadata registration
```

Avoid proxying large image uploads through the Next.js application server unless necessary.

---

# 16. Shared Contracts

Shared request/response schemas belong in:

```text
packages/shared/
```

Example:

```text
packages/shared/
├─ src/
│  ├─ schemas/
│  ├─ dto/
│  ├─ constants/
│  └─ types/
```

Use Zod schemas as the runtime source of truth when practical.

Example:

```ts
export const CreateVisitSchema = z.object({
  regionCode: z.string(),
  visitedAt: z.string().datetime().optional(),
  memo: z.string().max(2000).optional(),
});
```

Both `app/` and `backend/` may consume shared types.

Do not duplicate DTO definitions independently in both projects.

---

# 17. API Client Rules

The mobile app must not call `fetch()` directly from arbitrary UI components.

Use a dedicated API layer.

Example:

```text
app/src/services/api/
```

or feature-specific services:

```text
app/src/features/visits/services/visitApi.ts
```

UI components should consume hooks such as:

```ts
useVisits()
useCreateVisit()
useRegionPhotos()
```

Prefer TanStack Query for server state.

Do not duplicate server data unnecessarily inside Zustand.

---

# 18. State Management

Use the following rule:

## TanStack Query

Use for:

- API data
- visits
- photos
- user profile
- server synchronization

## Zustand

Use for:

- currently selected region
- temporary photo editor state
- map UI preferences
- unsaved local UI state

## React local state

Use for:

- component-only UI state
- modal visibility
- temporary inputs

Do not put all application state into one global store.

---

# 19. Performance Rules

Map performance is a core requirement.

Avoid:

- rendering unnecessarily detailed polygons
- parsing huge GeoJSON files on every screen load
- rendering full-resolution photos for every region
- unnecessary React re-renders
- fetching the same map asset repeatedly

Prefer:

- simplified paths
- memoized region components
- thumbnails
- image caching
- lazy loading
- region-level memoization
- preprocessed map assets

Any optimization must preserve recognizable administrative boundaries.

---

# 20. MultiPolygon Handling

Some administrative regions and countries consist of multiple disconnected areas.

Examples include:

- islands
- exclaves
- archipelagos

Do not assume every region is a single Polygon.

Rendering and preprocessing code must support:

```text
Polygon
MultiPolygon
```

All sub-polygons belonging to the same region should share:

- region identity
- selection state
- visit state
- photo data

---

# 21. Geographic Coordinate Logic

GPS-to-region matching is not required for the initial MVP.

If implemented later, isolate geographic lookup logic from UI code.

Possible approaches:

Client:

```text
Turf.js
booleanPointInPolygon
```

Server:

```text
PostgreSQL + PostGIS
ST_Contains / ST_Intersects
```

Do not add PostGIS until actual spatial queries justify it.

---

# 22. Error Handling

Every API request must handle:

- loading
- success
- empty state
- validation failure
- network failure
- server failure

Do not silently swallow errors.

User-facing errors should be understandable.

Development logs may contain technical context, but never log:

- access tokens
- signed URL secrets
- passwords
- raw authentication credentials

---

# 23. TypeScript Rules

Use strict TypeScript.

Avoid:

```ts
any
```

unless interfacing with an external library that genuinely lacks usable types.

Prefer:

```ts
unknown
```

followed by explicit validation.

Use domain-specific types.

Example:

```ts
type RegionCode = string;
type CountryCode = string;
```

Avoid passing loosely shaped objects across feature boundaries.

---

# 24. Naming Rules

React components:

```text
PascalCase
```

Examples:

```text
RegionMap.tsx
RegionPath.tsx
PhotoClip.tsx
```

Hooks:

```text
useSomething
```

Examples:

```text
useRegionMap.ts
useVisits.ts
```

Functions and variables:

```text
camelCase
```

Constants:

```text
UPPER_SNAKE_CASE
```

Directories:

```text
lowercase
```

Prefer descriptive names over abbreviations.

---

# 25. Component Rules

Components should remain focused.

Do not create one giant `MapScreen.tsx` containing:

- API requests
- SVG generation
- gesture logic
- photo cropping
- modal handling
- navigation
- analytics

Split these responsibilities.

Example:

```text
MapScreen
 ├─ MapModeTabs
 ├─ InteractiveRegionMap
 │   ├─ RegionLayer
 │   └─ RegionPhotoLayer
 └─ RegionBottomSheet
```

---

# 26. Backend Layering

Backend modules should separate:

```text
Route / Controller
        ↓
Service
        ↓
Repository
        ↓
Database
```

Do not place large business logic directly inside Next.js route handlers.

Example:

```text
backend/src/modules/visits/

├─ visit.route.ts
├─ visit.service.ts
├─ visit.repository.ts
├─ visit.schema.ts
└─ visit.types.ts
```

Equivalent folder conventions are acceptable if responsibility remains clear.

---

# 27. Environment Variables

Never hardcode secrets.

Environment variable names should remain technology-oriented rather than embedding
environment-specific product aliases. Infrastructure resource names should use `sasang`.

Examples:

```text
sasang-api
sasang-postgres
sasang-storage
sasang-production
```

Example backend variables:

```text
DATABASE_URL
S3_BUCKET
S3_REGION
S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY
AUTH_SECRET
```

Example app variables:

```text
EXPO_PUBLIC_API_URL
```

Only variables prefixed with `EXPO_PUBLIC_` should be assumed visible to the client.

Never store private secrets in mobile environment variables.

Provide:

```text
.env.example
```

without real credentials.

---

# 28. Testing Priorities

The most important tests are:

## App

- region selection
- Korea / World mode switching
- photo transform calculations
- map data parsing
- visited-region state
- API hooks

## Backend

- validation
- visit CRUD
- photo metadata persistence
- signed upload URL generation
- authorization

## Map preprocessing

Test that:

- every region has a code
- every region has a path
- paths contain valid coordinates
- MultiPolygon regions are preserved
- duplicate region codes do not exist

---

# 29. MVP Development Order

Agents should prioritize work in this order unless explicitly instructed otherwise.

## Phase 1

Build a Seoul-only proof of concept.

```text
서울 25개 구
      ↓
SVG paths
      ↓
region press
      ↓
photo selection
      ↓
polygon clipping
```

This validates the highest-risk technical requirement.

## Phase 2

Add:

- pinch zoom
- pan
- photo reposition
- photo scaling
- local persistence

## Phase 3

Add backend:

- visits
- photo metadata
- object storage
- synchronization

## Phase 4

Expand map data:

```text
Seoul
 ↓
Korea
 ↓
World
```

## Phase 5

Add secondary product features:

- visit list
- statistics
- profile
- filters
- sharing
- travel timeline

Do not begin with authentication, social feeds, or recommendation systems before map clipping is validated.

---

# 30. Agent Working Rules

When modifying this repository:

1. Inspect the existing implementation before adding new abstractions.
2. Prefer the smallest coherent change.
3. Do not introduce a new dependency if the current stack can solve the problem cleanly.
4. Preserve boundaries between `app/`, `backend/`, and `packages/shared/`.
5. Keep map rendering independent from backend persistence.
6. Avoid premature abstraction.
7. Do not rewrite unrelated code while implementing a feature.
8. Update tests when behavior changes.
9. Keep public API contracts backward compatible unless explicitly changing the API.
10. Document non-obvious architectural decisions.

---

# 31. Dependency Rules

Before adding a dependency, verify:

- the problem cannot be solved reasonably with existing dependencies
- the package is actively maintained
- Expo / React Native compatibility
- TypeScript support
- bundle-size impact
- native build requirements

Avoid dependency duplication.

For example, do not install multiple libraries that all provide basic date utilities or state management without a concrete reason.

---

# 32. Generated Files

Map path files and generated assets should clearly indicate that they are generated.

Example header:

```text
THIS FILE IS GENERATED.
DO NOT EDIT MANUALLY.
```

The generator script must be committed alongside the generated result.

Avoid hand-maintained generated geometry.

---

# 33. Git and Commit Scope

The canonical Git repository name is:

```text
sasang
```

Prefer commits scoped to one concern.

Examples:

```text
feat(app): add Korea map tab
feat(map): support multipolygon regions
feat(backend): add visit creation API
feat(photo): add region photo transform metadata
fix(map): preserve island polygons during simplification
```

Do not combine unrelated refactors with feature work.

Every completed task must create a Git commit using the following format:

```text
feat: 작업내용
```

The commit message must briefly describe the completed work in Korean or English after the
`feat:` prefix. Do not leave completed task changes uncommitted.

---

# 34. Non-Goals for Initial Development

Unless explicitly requested, do not prioritize:

- turn-by-turn navigation
- public social feed
- follower system
- chat
- travel recommendations
- complex GIS server
- real-time collaboration
- AR features
- detailed road maps
- native Google Maps integration
- Mapbox basemaps

Sasang's initial product is a personal visual travel map.

---

# 35. Key Product Principle

When choosing between implementation options for Sasang, prioritize the experience:

```text
"I can see my travel history through my own photos directly on the map."
```

over building a conventional geographic map.

The administrative boundary is a visual container.

The user's photo is the primary content.

The map is the composition layer.

All major UI and technical decisions should preserve this hierarchy.
