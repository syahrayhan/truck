# Hauler Truck - Mining Operations System

Aplikasi Flutter untuk mensimulasikan dan mengoperasikan satu siklus otomatis tambang dengan peta radius, event-sourcing, dan ketahanan offline. Server (Cloud Functions) bertindak sebagai arbiter status; client hanya mengirim telemetry dan intent.

## 📚 Dokumentasi Lengkap

Untuk dokumentasi lengkap dengan flowchart, diagram alur data, metode sinkronisasi, dan detail olah data, silakan lihat:

- **[DOKUMENTASI_LENGKAP.md](./DOKUMENTASI_LENGKAP.md)** - Dokumentasi utama lengkap
- **[DIAGRAM_FLOWCHART.md](./DIAGRAM_FLOWCHART.md)** - Flowchart detail untuk semua proses
- **[ARSITEKTUR_DAN_SYNC.md](./ARSITEKTUR_DAN_SYNC.md)** - Arsitektur detail dan metode sinkronisasi

## 🎯 Tujuan Utama

1. **Siklus Status Otomatis**: QUEUING → SPOTTING → LOADING → HAULING_LOAD → DUMPING → HAULING_EMPTY → STANDBY
2. **Trigger Otomatis**:
   - **T1**: QUEUING → SPOTTING saat loader.waitingTruck == true, hauler dalam radius loader
   - **T2**: HAULING_LOAD → DUMPING saat bodyUp == true di area dumping
3. **Simulasi pergerakan otomatis** di peta (OSM via flutter_map)
4. **Offline-first**: siklus tetap selesai lokal, lalu sinkron ke Firestore saat online

## 📐 Arsitektur

### State Machine

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HAULER STATE MACHINE                          │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────┐     Start      ┌──────────┐
    │ STANDBY  │ ──────────────→│ QUEUING  │←─────────────────────┐
    └──────────┘                └──────────┘                      │
         ↑                           │                            │
         │                           │ T1: In loader radius       │
         │                           │     + loader waiting       │
         │                           ↓                            │
         │                     ┌──────────┐                       │
         │                     │ SPOTTING │                       │
         │                     └──────────┘                       │
         │                           │                            │
         │                           │ Loader confirmed           │
         │                           ↓                            │
         │                     ┌──────────┐                       │
         │                     │ LOADING  │                       │
         │                     └──────────┘                       │
         │                           │                            │
         │                           │ Loading complete           │
         │                           ↓                            │
         │                    ┌─────────────┐                     │
         │                    │HAULING_LOAD │                     │
         │                    └─────────────┘                     │
         │                           │                            │
         │                           │ T2: In dump radius         │
         │                           │     + bodyUp = true        │
         │                           ↓                            │
         │                     ┌──────────┐                       │
         │                     │ DUMPING  │                       │
         │                     └──────────┘                       │
         │                           │                            │
         │                           │ bodyUp = false             │
         │                           ↓                            │
         │                   ┌──────────────┐                     │
         └───────────────────│HAULING_EMPTY │─────────────────────┘
                             └──────────────┘
                                   ↓
                             Back to QUEUING
                             (cycle repeats)
```

### Alur Data

```
┌──────────────────────────────────────────────────────────────────────┐
│                           DATA FLOW                                   │
└──────────────────────────────────────────────────────────────────────┘

   HAULER APP                    FIRESTORE                CLOUD FUNCTIONS
  ┌──────────┐                 ┌──────────┐              ┌──────────────┐
  │          │   Telemetry     │          │   Trigger    │              │
  │  Location├────────────────→│telemetry ├─────────────→│processTelem. │
  │  + Body  │                 │          │              │              │
  └──────────┘                 └──────────┘              └──────┬───────┘
       │                                                        │
       │                                                        │ Check
       │                                                        │ Auto
       │    Intent                                              │ Trans.
       ├──────────────────────→┌──────────┐                     │
       │  (REQUEST_SPOTTING,   │ intents  │                     │
       │   CONFIRM_LOADING,    └────┬─────┘                     │
       │   etc.)                    │                           │
       │                            │ Trigger                   │
       │                            ↓                           ↓
       │                      ┌──────────────┐           ┌──────────────┐
       │                      │processIntent │           │ Validate &   │
       │                      └──────┬───────┘           │ Apply Trans. │
       │                             │                   └──────┬───────┘
       │                             │ Validate                 │
       │                             ↓                          │
       │                      ┌──────────────┐                  │
       │                      │ hauler_events│←─────────────────┘
       │                      └──────────────┘
       │                             │
       │                             │ Update
       │                             ↓
       │                      ┌──────────────┐
       │◀─────────────────────│   haulers    │
       │    Stream updates    └──────────────┘
       │
  ┌────┴─────┐
  │ UI Update│
  │ (Local   │
  │ Optimist)│
  └──────────┘
```

### Event Sourcing

```
┌───────────────────────────────────────────────────────────────────────┐
│                          EVENT SOURCING                                │
└───────────────────────────────────────────────────────────────────────┘

  Event Structure:
  ┌─────────────────────────────────────────────────────────────────────┐
  │ {                                                                    │
  │   id: "uuid",                                                        │
  │   haulerId: "HLR-xxxx",                                             │
  │   cycleId: "cycle-uuid",                                            │
  │   fromStatus: "QUEUING",                                            │
  │   toStatus: "SPOTTING",                                             │
  │   cause: "ENTERED_LOADER_RADIUS",                                   │
  │   deviceTime: "2024-01-15T10:30:00Z",                              │
  │   serverTime: <server timestamp>,                                   │
  │   seq: 5,                           ← Monotonic per cycle          │
  │   dedupKey: "HLR-xxxx_cycle_5_T1"   ← Idempotency key             │
  │ }                                                                    │
  └─────────────────────────────────────────────────────────────────────┘

  Deduplication:
  - dedupKey = `${haulerId}_${cycleId}_${seq}_${cause}`
  - Uses dedupKey as document ID for idempotent writes
  - Server rejects duplicate events based on seq ordering
```

## 📊 Desain Data Firestore

### Collections

```
firestore/
├── haulers/                    # Hauler/Truck documents
│   └── {haulerId}/
│       ├── id: string
│       ├── currentStatus: string
│       ├── lastStatusChangeAt: timestamp
│       ├── location: { lat, lng, accuracy }
│       ├── bodyUp: boolean
│       ├── online: boolean
│       ├── deviceTime: timestamp
│       ├── cycleId: string?
│       ├── assignedLoaderId: string?
│       └── eventSeq: number
│
├── hauler_events/              # Event sourcing log
│   └── {dedupKey}/
│       ├── haulerId: string
│       ├── cycleId: string
│       ├── fromStatus: string?
│       ├── toStatus: string?
│       ├── cause: string
│       ├── deviceTime: timestamp
│       ├── serverTime: timestamp
│       ├── seq: number
│       ├── dedupKey: string
│       └── metadata: object?
│
├── telemetry/                  # Location & sensor data
│   └── {telemetryId}/
│       ├── haulerId: string
│       ├── cycleId: string
│       ├── lat: number
│       ├── lng: number
│       ├── accuracy: number?
│       ├── bodyUp: boolean
│       ├── deviceTime: timestamp
│       └── createdAt: timestamp
│
├── cycles/                     # Cycle tracking
│   └── {cycleId}/
│       ├── id: string
│       ├── haulerId: string
│       ├── loaderId: string?
│       ├── loaderLocation: { lat, lng }
│       ├── dumpLocation: { lat, lng }
│       ├── dumpRadius: number
│       ├── steps: CycleStep[]
│       ├── completed: boolean
│       ├── anomalies: string[]
│       ├── startedAt: timestamp
│       └── completedAt: timestamp?
│
├── loaders/                    # Loader equipment
│   └── {loaderId}/
│       ├── id: string
│       ├── name: string
│       ├── location: { lat, lng }
│       ├── waitingTruck: boolean
│       └── radius: number
│
└── intents/                    # Client intents for server arbitration
    └── {intentId}/
        ├── haulerId: string
        ├── cycleId: string
        ├── type: string
        ├── requestedStatus: string?
        ├── deviceTime: timestamp
        ├── location: { lat, lng }?
        ├── context: object?
        ├── processed: boolean
        └── resultEventId: string?
```

## 🔄 Offline-First & Rekonsiliasi

### Mekanisme

1. **Firestore Persistence**: Enabled by default untuk semua writes
2. **Offline Queue**: Hive-based queue untuk events, telemetry, dan intents
3. **Idempotent Writes**: Menggunakan dedupKey sebagai document ID
4. **Monotonic Sequence**: seq per cycle untuk ordering
5. **Device Time Tolerance**: Server menyimpan deviceTime dan serverTime terpisah

### Alur Offline

```
┌─────────────────────────────────────────────────────────────────┐
│                      OFFLINE FLOW                                │
└─────────────────────────────────────────────────────────────────┘

  [ONLINE]                    [OFFLINE]                  [BACK ONLINE]
     │                            │                           │
     │  Normal operation          │  Local state machine      │
     │  via Firestore             │  continues working        │
     │                            │                           │
     │                            │  Events queued in         │
     │                            │  Hive offline queue       │
     │                            │                           │
     │                            │  UI shows optimistic      │
     │                            │  state updates            │
     │                            │                           │
     │                            │                           │
     │                            │◀──────────────────────────│
     │                            │  Connectivity restored    │
     │                            │                           │
     │◀───────────────────────────│  Queue processed:         │
     │                            │  - Events synced          │
     │                            │  - Telemetry synced       │
     │                            │  - Intents sent           │
     │                            │                           │
     │  Server validates          │                           │
     │  and may correct           │                           │
     │                            │                           │
     │  If correction:            │                           │
     │  UI shows "corrected       │                           │
     │  by server" banner         │                           │
     └────────────────────────────┴───────────────────────────┘
```

### GPS Accuracy Guard

- Jika `accuracy > 50m`, transisi berbasis lokasi ditunda
- Melindungi dari false triggers saat GPS tidak stabil

## 🗺️ Fitur Peta

- **flutter_map + OpenStreetMap** (gratis, tidak perlu API key)
- **Marker Hauler**: Menunjukkan posisi dan status real-time
- **Circle Loader**: Radius hijau menandai zona loading
- **Circle Dump Point**: Radius oranye menandai zona dumping
- **Follow Mode**: Peta mengikuti pergerakan hauler

## 🎮 Fitur & UX

1. **Status Panel**: Menampilkan status saat ini dengan progress indicator
2. **Body Up/Down Button**: Simulasi sensor bak dump
3. **Simulation Mode**: Pergerakan otomatis untuk testing
4. **Event Log**: Terminal-style log untuk debugging
5. **Server Correction Banner**: Notifikasi jika status dikoreksi server
6. **Offline Indicator**: Status koneksi dan pending queue count

## 🚀 Menjalankan Aplikasi

### Prerequisites

- Flutter SDK >= 3.10.4
- Firebase project (untuk Firestore)
- Node.js >= 18 (untuk Cloud Functions)

### Setup

```bash
# Clone dan install dependencies
cd hauler_truck
flutter pub get

# Setup Firebase (optional untuk demo mode)
flutterfire configure

# Jalankan aplikasi
flutter run
```

### Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## 🧪 Pengujian

### Skenario Test Offline

1. Start cycle (QUEUING)
2. **Putus koneksi**
3. Simulasi pergerakan ke loader (T1 triggers locally)
4. Loading complete → HAULING_LOAD
5. Pergerakan ke dump point
6. Body Up → DUMPING (T2 triggers locally)
7. Body Down → HAULING_EMPTY
8. **Restore koneksi**
9. Verifikasi: Status akhir sama dengan server

### Acceptance Criteria

- [ ] Siklus tetap selesai saat offline
- [ ] Tidak ada transisi duplikat setelah sync
- [ ] Server dapat mengoreksi status jika diperlukan
- [ ] Latensi transisi tercatat di events
- [ ] GPS accuracy guard bekerja

## 📝 Ringkasan Keputusan Kunci

| Keputusan | Alasan |
|-----------|--------|
| **Server-Arbiter** | Single source of truth, mencegah state divergence |
| **Event-Sourcing** | Audit trail lengkap, replay capability, debugging |
| **Offline-First** | Mining operations sering di area sinyal lemah |
| **Intent Pattern** | Client tidak set status langsung, hanya request |
| **Idempotent Events** | Mencegah duplikasi saat retry offline queue |
| **OSM/flutter_map** | Gratis, tidak perlu API key, cukup untuk demo |

## ⚠️ Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| **Clock drift** antar device | Simpan deviceTime dan serverTime terpisah; ordering by seq, bukan timestamp |
| **GPS tidak akurat** | Guard: tunda transisi jika accuracy > threshold |
| **Konflik status offline-online** | Server sebagai arbiter final; UI tampilkan correction banner |
| **Queue overflow saat offline lama** | Limit queue size; prioritaskan events over telemetry |
| **Network flaky** | Exponential backoff retry; Firestore built-in persistence |

## 📁 Struktur Proyek

```
lib/
├── core/
│   ├── constants.dart        # App constants, enums
│   └── state_machine.dart    # Status transitions & guards
├── models/
│   ├── hauler.dart           # Hauler, Loader, DumpPoint, GeoLocation
│   └── events.dart           # HaulerEvent, Telemetry, Cycle, Intent
├── services/
│   ├── firestore_service.dart    # Firestore with offline support
│   ├── location_service.dart     # GPS tracking
│   ├── cycle_service.dart        # Cycle & transition management
│   ├── simulation_service.dart   # Auto movement simulation
│   └── offline_queue_service.dart # Hive-based offline queue
├── providers/
│   └── hauler_provider.dart      # Main state provider
├── screens/
│   └── home_screen.dart          # Main screen
├── widgets/
│   ├── hauler_map.dart           # Map with markers & circles
│   ├── status_panel.dart         # Status display & controls
│   └── event_log_panel.dart      # Debug event log
└── main.dart

functions/
├── index.ts                  # Cloud Functions (arbiter)
├── package.json
└── tsconfig.json
```

## 📜 License

MIT License - See LICENSE file for details.
