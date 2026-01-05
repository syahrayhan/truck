# Hauler Truck - Mining Operations System

Aplikasi Flutter untuk mengelola operasi tambang dengan sistem **offline-first** dan **event-sourcing**. Sistem ini menggunakan pola **offline-first** dimana semua data selalu disimpan ke local queue terlebih dahulu, kemudian di-sync ke server di background.

---

## 📊 Flowchart Proses Simpan Status

### Overview Proses Simpan Status

Proses simpan status dimulai ketika terjadi transisi status hauler (dari status A ke status B). Sistem menggunakan pola **offline-first** dimana data selalu disimpan ke local queue (Hive) terlebih dahulu, kemudian di-sync ke Firestore di background.

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART PROSES SIMPAN STATUS                               │
│          (Status Transition → Local Queue → Firestore)              │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Status          │
│ Transition      │
│ Triggered       │
│                 │
│ - Auto (T1/T2)  │
│ - Manual        │
│ - System        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ HaulerBloc      │
│ _updateHauler   │
│ Status()        │
│                 │
│ Dipanggil       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Prepare Data    │
│                 │
│ - Get previous  │
│   status        │
│ - Get new       │
│   status        │
│ - Get cause     │
│ - Increment seq │
│ - Get timestamp │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create Event    │
│ Entity          │
│                 │
│ - Generate UUID │
│ - haulerId       │
│ - cycleId        │
│ - fromStatus     │
│ - toStatus       │
│ - cause          │
│ - seq            │
│ - dedupKey       │
│ - deviceTime     │
│ - metadata       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Save Event      │
│ (Step 1)        │
│                 │
│ haulerRepository│
│ .saveEvent()    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    OFFLINE-FIRST: SAVE EVENT                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                       │
│  │ ALWAYS: Queue   │                                       │
│  │ to Hive First   │                                       │
│  │                 │                                       │
│  │ - Create        │                                       │
│  │   QueueItemData │                                       │
│  │ - Type: event   │                                       │
│  │ - Store event   │                                       │
│  │   data          │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │ Hive Storage    │                                       │
│  │                 │                                       │
│  │ - Serialize to  │                                       │
│  │   JSON          │                                       │
│  │ - Store in box: │                                       │
│  │   offline_queue │                                       │
│  │ - Generate      │                                       │
│  │   queueKey      │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │ Check Online?   │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ├─── OFFLINE ──▶ [Return Success]                │
│           │     (Queue only)                               │
│           │                                                 │
│           ▼ ONLINE                                         │
│  ┌─────────────────┐                                       │
│  │ Background Sync │                                       │
│  │                 │                                       │
│  │ - Firestore     │                                       │
│  │   saveEvent()   │                                       │
│  │ - Collection:   │                                       │
│  │   hauler_events │                                       │
│  │ - Doc ID:        │                                       │
│  │   dedupKey      │                                       │
│  │ - Merge: true   │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ├─── SUCCESS ──▶ [Remove from Queue]             │
│           │                                                 │
│           └─── FAIL ──▶ [Keep in Queue]                    │
│                     (Will sync later)                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ Update Local    │
│ Hauler State    │
│                 │
│ - currentStatus │
│ - lastStatus    │
│   ChangeAt      │
│ - eventSeq      │
│ - deviceTime    │
│ - cycleId       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Hauler   │
│ (Step 2)        │
│                 │
│ haulerRepository│
│ .updateHauler() │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│              OFFLINE-FIRST: UPDATE HAULER                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                       │
│  │ ALWAYS: Queue   │                                       │
│  │ to Hive First   │                                       │
│  │                 │                                       │
│  │ - Create        │                                       │
│  │   QueueItemData │                                       │
│  │ - Type:         │                                       │
│  │   haulerUpdate  │                                       │
│  │ - Store update  │                                       │
│  │   data          │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │ Hive Storage    │                                       │
│  │                 │                                       │
│  │ - Serialize to  │                                       │
│  │   JSON          │                                       │
│  │ - Store in box: │                                       │
│  │   offline_queue │                                       │
│  │ - Generate      │                                       │
│  │   queueKey      │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │ Check Online?   │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ├─── OFFLINE ──▶ [Return Success]                │
│           │     (Queue only)                               │
│           │                                                 │
│           ▼ ONLINE                                         │
│  ┌─────────────────┐                                       │
│  │ Background Sync │                                       │
│  │                 │                                       │
│  │ - Firestore     │                                       │
│  │   updateHauler()│                                       │
│  │ - Collection:   │                                       │
│  │   haulers       │                                       │
│  │ - Document:     │                                       │
│  │   {haulerId}    │                                       │
│  │ - Add           │                                       │
│  │   deviceTime    │                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ├─── SUCCESS ──▶ [Remove from Queue]             │
│           │                                                 │
│           └─── FAIL ──▶ [Keep in Queue]                    │
│                     (Will sync later)                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ Update Cycle    │
│ Steps (Step 3)  │
│                 │
│ - Create step   │
│ - Add to cycle  │
│ - Save cycle    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Emit New State  │
│                 │
│ - Updated hauler│
│ - Updated cycle │
│ - New eventSeq  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update UI       │
│                 │
│ - Status panel  │
│ - Event log     │
│ - Map markers   │
└────────┬────────┘
         │
         ▼
        END
```

---

## 🔄 Proses Sync Queue ke Firestore

Ketika data sudah di-queue di Hive, proses sync ke Firestore terjadi di background:

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART SYNC QUEUE KE FIRESTORE                          │
└─────────────────────────────────────────────────────────────────────┘

[Connectivity Detected / Background Sync Triggered]
         │
         ▼
┌─────────────────┐
│ Get Pending     │
│ Queue Items     │
│                 │
│ - Read from     │
│   Hive box      │
│ - Deserialize   │
│   JSON          │
│ - Sort by       │
│   createdAt     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ FOR each item:  │
│                 │
│ Check retry     │
│ count           │
└────────┬────────┘
         │
         ├─── Retry ≥ Max ──▶ [Remove Item] ──▶ [Next Item]
         │
         ▼ Retry < Max
┌─────────────────┐
│ Process Item    │
│ by Type         │
└────────┬────────┘
         │
         ├─── Type: event ──▶ [Path A: Save Event]
         │
         ├─── Type: haulerUpdate ──▶ [Path B: Update Hauler]
         │
         └─── Type: telemetry ──▶ [Path C: Save Telemetry]
         │
         ▼ [Path A: Save Event]
┌─────────────────┐
│ Firestore       │
│ saveEvent       │
│                 │
│ collection:     │
│   hauler_events │
│ document ID:    │
│   {dedupKey}    │
│ operation:      │
│   set(merge:true)│
│                 │
│ Note: dedupKey  │
│ as doc ID      │
│ ensures         │
│ idempotency     │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ [Next Item]
         │
         └─── FAIL ──▶ [Increment Retry Count] ──▶ [Next Item]
         │
         ▼ [Path B: Update Hauler]
┌─────────────────┐
│ Firestore       │
│ updateHauler    │
│                 │
│ collection:     │
│   haulers       │
│ document:       │
│   {haulerId}    │
│ operation:      │
│   update()      │
│                 │
│ - Add deviceTime│
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ [Next Item]
         │
         └─── FAIL ──▶ [Increment Retry Count] ──▶ [Next Item]
         │
         ▼ [Path C: Save Telemetry]
┌─────────────────┐
│ Firestore       │
│ saveTelemetry   │
│                 │
│ collection:     │
│   telemetry     │
│ document ID:    │
│   {telemetryId} │
│ operation:      │
│   set()         │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ [Next Item]
         │
         └─── FAIL ──▶ [Increment Retry Count] ──▶ [Next Item]
         │
         ▼ [All Items Processed]
        END
```

---

## 📝 Detail Proses Simpan Status

### 1. Trigger Status Transition

Status transition dapat dipicu oleh:
- **Auto Transition T1**: QUEUING → SPOTTING (masuk radius loader + loader waiting)
- **Auto Transition T2**: HAULING_LOAD → DUMPING (masuk radius dump + bodyUp)
- **Manual Transition**: User klik tombol transisi manual
- **System Transition**: Cycle start/complete

### 2. Create Event Entity

```dart
HaulerEventEntity.create(
  id: UUID.v4(),
  haulerId: "HLR-xxxx",
  cycleId: "cycle-xxxx",
  fromStatus: HaulerStatus.queuing,
  toStatus: HaulerStatus.spotting,
  cause: TransitionCause.enteredLoaderRadius,
  seq: eventSeq + 1,
  metadata: {
    'location': {lat, lng},
    'bodyUp': false,
  }
)
```

**dedupKey Format**: `${haulerId}_${cycleId}_${seq}_${cause.code}`

### 3. Save Event (Offline-First)

**Proses**:
1. **ALWAYS**: Queue ke Hive terlebih dahulu
   - Create `QueueItemData` dengan type `event`
   - Serialize event data ke JSON
   - Store di Hive box `offline_queue`
   - Generate `queueKey` untuk tracking

2. **IF ONLINE**: Background sync ke Firestore
   - Convert entity ke model
   - Write ke collection `hauler_events`
   - Document ID = `dedupKey` (idempotent)
   - Set `serverTime` = server timestamp
   - Merge strategy untuk mencegah overwrite

3. **Return**: Always return success (optimistic update)

### 4. Update Hauler (Offline-First)

**Proses**:
1. **ALWAYS**: Queue ke Hive terlebih dahulu
   - Create `QueueItemData` dengan type `haulerUpdate`
   - Store update data: `{currentStatus, lastStatusChangeAt, eventSeq, cycleId}`
   - Serialize ke JSON
   - Store di Hive box `offline_queue`

2. **IF ONLINE**: Background sync ke Firestore
   - Write ke collection `haulers`
   - Document = `{haulerId}`
   - Add `deviceTime` = client timestamp
   - Update fields: `currentStatus`, `lastStatusChangeAt`, `eventSeq`, `cycleId`

3. **Return**: Always return success (optimistic update)

### 5. Update Cycle Steps

- Create `CycleStepEntity` dengan status baru
- Add step ke cycle.steps array
- Update cycle di Firestore (jika online) atau queue (jika offline)

### 6. Emit New State

- Update local state dengan:
  - Updated hauler entity
  - Updated cycle entity
  - New eventSeq
- UI akan otomatis update melalui BLoC stream

---

## 🔑 Key Features

### Offline-First Pattern

- **Selalu queue dulu**: Semua data selalu disimpan ke Hive queue terlebih dahulu
- **Background sync**: Sync ke Firestore dilakukan di background (non-blocking)
- **Optimistic updates**: UI langsung update, tidak menunggu server response
- **Retry mechanism**: Item yang gagal sync akan di-retry otomatis

### Idempotency

- **dedupKey sebagai Document ID**: Event menggunakan dedupKey sebagai document ID di Firestore
- **Merge strategy**: Menggunakan `SetOptions(merge: true)` untuk mencegah overwrite
- **Sequence number**: Monotonic seq per cycle untuk ordering
- **No duplicates**: Retry tidak akan membuat duplicate karena dedupKey sama

### Error Handling

- **Max retry**: Item yang gagal sync akan di-retry maksimal 5 kali
- **Queue persistence**: Data tetap aman di Hive meski app restart
- **Background sync**: Sync tidak blocking UI thread
- **Automatic recovery**: Sync otomatis saat connectivity restored

---

## 📊 Data Flow Summary

```
Status Transition
    ↓
Create Event Entity
    ↓
Queue Event to Hive (ALWAYS)
    ↓
Background Sync to Firestore (IF ONLINE)
    ↓
Update Local Hauler State
    ↓
Queue Hauler Update to Hive (ALWAYS)
    ↓
Background Sync to Firestore (IF ONLINE)
    ↓
Update Cycle Steps
    ↓
Emit New State
    ↓
UI Update
```

---

## 🚀 Menjalankan Aplikasi

```bash
# Install dependencies
flutter pub get

# Run app
flutter run
```

---

## 📁 Struktur Proyek

```
lib/
├── core/
│   ├── constants.dart        # Status, causes, constants
│   └── state_machine.dart    # State machine & guards
├── domain/
│   ├── entities/             # Business objects
│   ├── repositories/         # Repository interfaces
│   └── usecases/             # Business logic
├── data/
│   ├── datasources/          # Firestore & Hive
│   ├── models/               # DTOs
│   └── repositories/         # Repository implementations
└── presentation/
    ├── bloc/                 # State management
    ├── pages/                # Screens
    └── widgets/              # UI components
```

---

## 📜 License

MIT License
