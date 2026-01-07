# Dokumentasi Alur Data Aplikasi Hauler Truck

## 📋 Daftar Isi
1. [Arsitektur Aplikasi](#arsitektur-aplikasi)
2. [Lapisan Data Flow](#lapisan-data-flow)
3. [Alur Data Utama](#alur-data-utama)
4. [Offline-First Pattern](#offline-first-pattern)
5. [Connectivity & Sync Strategy](#connectivity--sync-strategy)
6. [State Management](#state-management)
7. [Diagram Alur Data](#diagram-alur-data)

---

## Arsitektur Aplikasi

Aplikasi ini menggunakan **Clean Architecture** dengan pola **BLoC (Business Logic Component)** untuk state management. Struktur terdiri dari 3 lapisan utama:

### 1. **Presentation Layer** (`lib/presentation/`)
- **BLoC**: Mengelola state dan business logic untuk UI
- **Pages**: Halaman-halaman aplikasi
- **Widgets**: Komponen UI yang dapat digunakan kembali

### 2. **Domain Layer** (`lib/domain/`)
- **Entities**: Model bisnis murni (tanpa dependensi eksternal)
- **Repositories**: Interface/abstraksi untuk akses data
- **Use Cases**: Business logic yang dapat digunakan kembali

### 3. **Data Layer** (`lib/data/`)
- **Data Sources**: 
  - **Remote**: Firestore (Cloud Firestore)
  - **Local**: Hive (Offline Queue)
- **Repositories**: Implementasi konkret dari domain repositories
- **Models**: Model data dengan serialisasi/deserialisasi

---

## Lapisan Data Flow

### Flow Diagram Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  HomePage    │  │   Widgets    │  │   BLoC       │     │
│  │              │──│              │──│              │     │
│  │  (UI)        │  │  (Components)│  │  (State)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Entities    │  │  Repositories│  │  Use Cases  │     │
│  │              │  │  (Interface) │  │             │     │
│  │  (Business)  │  │              │  │  (Logic)    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Repository  │  │  Data Source │  │   Models    │     │
│  │  (Impl)      │──│  (Remote/    │──│             │     │
│  │              │  │   Local)     │  │  (Serial)    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
        ┌──────────────┐        ┌──────────────┐
        │  Firestore   │        │  Hive (Local)│
        │  (Cloud)     │        │  (Offline)   │
        └──────────────┘        └──────────────┘
```

---

## Alur Data Utama

### 1. **Inisialisasi Aplikasi**

```
main.dart
  │
  ├─► Firebase.initializeApp()
  │
  ├─► OfflineQueueDataSource.initialize()
  │   └─► Hive.initFlutter()
  │       └─► Hive.openBox('offline_queue')
  │
  ├─► di.init(haulerId)
  │   └─► Dependency Injection Setup:
  │       ├─► BLoCs (HaulerBloc, SimulationBloc)
  │       ├─► Repositories (HaulerRepository, CycleRepository, dll)
  │       ├─► Data Sources (FirestoreDataSource, OfflineQueueDataSource)
  │       └─► Use Cases
  │
  └─► HaulerTruckApp
      └─► HomePage
          └─► InitializeHauler Event
```

### 2. **Alur Inisialisasi Hauler**

```
HomePage.initState()
  │
  └─► HaulerBloc.add(InitializeHauler)
      │
      ├─► locationRepository.initialize()
      │   └─► Setup GPS location service
      │
      ├─► haulerRepository.getOrCreateHauler(haulerId)
      │   │
      │   ├─► FirestoreDataSource.getHauler(haulerId)
      │   │   └─► Firestore: haulers/{haulerId}
      │   │
      │   └─► Jika tidak ada:
      │       └─► FirestoreDataSource.createHauler()
      │           └─► Buat hauler baru di Firestore
      │
      ├─► _setupLoadersStream()
      │   └─► loaderRepository.streamLoaders()
      │       └─► Firestore: loaders collection (real-time)
      │
      ├─► _setupHaulerStream(haulerId)
      │   └─► haulerRepository.streamHauler(haulerId)
      │       └─► Firestore: haulers/{haulerId} (real-time)
      │
      ├─► _setupConnectivityStream()
      │   └─► connectivityRepository.connectivityStream
      │       └─► Monitor koneksi internet
      │
      └─► _setupPingStream()
          └─► connectivityRepository.pingStream
              └─► PingService.startMonitoring()
                  └─► Measure ping setiap 5 detik
```

### 3. **Alur Update Location**

```
LocationRepository (GPS)
  │
  └─► HaulerBloc.add(UpdateLocation)
      │
      ├─► Update local state
      │   └─► emit(state.copyWith(hauler: updatedHauler))
      │
      ├─► haulerRepository.updateLocation(haulerId, location)
      │   │
      │   ├─► OfflineQueue.enqueue(QueueItemData)
      │   │   └─► Hive: Simpan ke local queue (ALWAYS)
      │   │
      │   └─► Jika online:
      │       └─► FirestoreDataSource.updateHauler()
      │           └─► Firestore: haulers/{haulerId}.update()
      │           └─► OfflineQueue.remove(queueKey) // Jika sukses
      │
      └─► ProcessAutoTransitions
          └─► Cek kondisi untuk auto-transition status
```

### 4. **Alur Status Transition**

```
User Action / Auto Transition
  │
  └─► HaulerBloc.add(StartCycleEvent / ManualTransition / dll)
      │
      ├─► Validasi transition
      │   └─► HaulerStateMachine.canTransition(from, to)
      │
      ├─► _updateHaulerStatus(newStatus, cause)
      │   │
      │   ├─► Buat HaulerEventEntity
      │   │   └─► Event dengan seq number
      │   │
      │   ├─► haulerRepository.saveEvent(event)
      │   │   ├─► OfflineQueue.enqueue(event) // ALWAYS
      │   │   └─► Jika online: Firestore.saveEvent()
      │   │
      │   ├─► haulerRepository.updateHauler(status)
      │   │   ├─► OfflineQueue.enqueue(update) // ALWAYS
      │   │   └─► Jika online: Firestore.updateHauler()
      │   │
      │   └─► cycleRepository.updateCycle(step)
      │       ├─► OfflineQueue.enqueue(cycle) // ALWAYS
      │       └─► Jika online: Firestore.updateCycle()
      │
      └─► emit(state.copyWith(hauler: updatedHauler))
```

### 5. **Alur Sync Offline Data**

```
ConnectivityRepository
  │
  ├─► PingService mengukur ping
  │   └─► PingResult dengan quality:
  │       ├─► excellent (< 100ms) → SyncStrategy.immediate
  │       ├─► good (100-300ms) → SyncStrategy.batched
  │       ├─► fair (300-500ms) → SyncStrategy.delayed
  │       ├─► poor (500-1000ms) → SyncStrategy.criticalOnly
  │       └─► offline → SyncStrategy.queue
  │
  └─► _handlePingBasedSync(pingResult)
      │
      ├─► immediate: Sync langsung
      │   └─► _processOfflineQueue()
      │
      ├─► batched/delayed: Setup timer
      │   └─► Timer → _processOfflineQueue()
      │
      ├─► criticalOnly: Sync hanya critical items
      │   └─► _processCriticalItemsOnly()
      │       └─► Hanya event & haulerUpdate
      │
      └─► queue: Tidak sync, tunggu koneksi lebih baik
```

### 6. **Alur Process Offline Queue**

```
_processOfflineQueue()
  │
  ├─► offlineQueue.getPendingItems()
  │   └─► Hive: Baca semua item dari queue
  │
  ├─► Untuk setiap item:
  │   │
  │   ├─► Cek retryCount < maxRetries
  │   │
  │   ├─► _syncItem(item)
  │   │   │
  │   │   ├─► Jika event:
  │   │   │   └─► Firestore: hauler_events/{dedupKey}.set()
  │   │   │
  │   │   ├─► Jika telemetry:
  │   │   │   └─► Firestore: telemetry/{id}.set()
  │   │   │
  │   │   ├─► Jika haulerUpdate:
  │   │   │   └─► Firestore: haulers/{haulerId}.update()
  │   │   │
  │   │   └─► Jika intent:
  │   │       └─► Firestore: intents/{id}.set()
  │   │
  │   ├─► Jika sukses:
  │   │   └─► offlineQueue.remove(queueKey)
  │   │
  │   └─► Jika gagal:
  │       └─► offlineQueue.incrementRetry(queueKey)
```

### 7. **Alur Server Correction**

```
Firestore: haulers/{haulerId} (real-time stream)
  │
  └─► HaulerBloc._setupHaulerStream()
      │
      └─► HaulerUpdatedFromServer event
          │
          ├─► Bandingkan serverSeq vs localSeq
          │
          ├─► Jika serverSeq > localSeq:
          │   ├─► Server correction detected
          │   ├─► Update local state sesuai server
          │   └─► Log: "Server correction: {local} → {server}"
          │
          └─► Jika localSeq > serverSeq:
              └─► Local update akan sync ke server
```

---

## Offline-First Pattern

### Prinsip Utama

1. **Always Queue First**: Semua update selalu disimpan ke local queue terlebih dahulu
2. **Optimistic Updates**: UI langsung update tanpa menunggu server
3. **Background Sync**: Sync ke server dilakukan di background (non-blocking)
4. **Retry Mechanism**: Item yang gagal sync akan di-retry dengan batas maksimal

### Apa itu "Enqueue"?

**Enqueue** = Menambahkan item ke dalam antrian (queue) untuk diproses nanti.

#### Konsep Queue (Antrian)

Queue bekerja seperti antrian di kasir:
- **Enqueue** = Masuk ke belakang antrian (tambah item)
- **Dequeue** = Keluar dari depan antrian (proses item)
- **FIFO** = First In First Out (yang masuk pertama, keluar pertama)

#### Implementasi di Aplikasi

```dart
// Contoh: Update hauler status
final queueKey = await offlineQueue.enqueue(QueueItemData.create(
  id: haulerId,
  type: QueueItemType.haulerUpdate,
  data: {'haulerId': haulerId, 'update': data},
));
```

**Apa yang terjadi saat enqueue?**

1. **Buat QueueItemData**:
   ```dart
   QueueItemData {
     id: "HLR-12345678",
     type: QueueItemType.haulerUpdate,
     data: {
       'haulerId': 'HLR-12345678',
       'update': {
         'currentStatus': 'LOADING',
         'eventSeq': 5
       }
     },
     createdAt: DateTime.now(),
     retryCount: 0
   }
   ```

2. **Generate Queue Key**:
   ```dart
   // Format: {type}_{id}_{timestamp}
   key = "haulerUpdate_HLR-12345678_1703123456789"
   ```

3. **Simpan ke Hive**:
   ```dart
   // Hive Box: "offline_queue"
   _queueBox.put(key, jsonEncode(item.toMap()))
   ```

4. **Return Queue Key**:
   - Key ini digunakan nanti untuk:
     - Remove item setelah sync sukses
     - Increment retry count jika gagal
     - Track item di queue

#### Visualisasi Enqueue

```
┌─────────────────────────────────────────────────────────┐
│  User Action: Update Hauler Status                       │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  HaulerRepository.updateHauler()                         │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  ENQUEUE (Step 1)     │
        │                       │
        │  offlineQueue.enqueue()│
        │         │             │
        │         ▼             │
        │  ┌───────────────┐    │
        │  │ QueueItemData │    │
        │  │ - id          │    │
        │  │ - type        │    │
        │  │ - data        │    │
        │  │ - createdAt   │    │
        │  └───────────────┘    │
        │         │             │
        │         ▼             │
        │  Generate Key:        │
        │  "haulerUpdate_...    │
        │   _1703123456789"     │
        │         │             │
        │         ▼             │
        │  Hive Box.put()       │
        │  ┌───────────────┐    │
        │  │ offline_queue │    │
        │  │ Box           │    │
        │  │               │    │
        │  │ Key → JSON    │    │
        │  └───────────────┘    │
        │         │             │
        │         ▼             │
        │  Return queueKey      │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  SYNC (Step 2)        │
        │  (Background)          │
        │                       │
        │  If online:           │
        │  └─► Firestore        │
        │      └─► If success:  │
        │          remove(key)  │
        └───────────────────────┘
```

#### Mengapa Enqueue Penting?

1. **Offline Support**: 
   - Data tetap tersimpan meski offline
   - Akan sync otomatis saat online

2. **Data Integrity**:
   - Tidak ada data yang hilang
   - Semua update tercatat

3. **Retry Mechanism**:
   - Jika sync gagal, item tetap di queue
   - Akan di-retry nanti

4. **Optimistic Updates**:
   - UI langsung update
   - Sync di background

#### Contoh Flow Lengkap

```
1. User update location
   │
   ▼
2. HaulerBloc.add(UpdateLocation)
   │
   ▼
3. haulerRepository.updateLocation()
   │
   ├─► ENQUEUE (Selalu dilakukan)
   │   └─► offlineQueue.enqueue()
   │       └─► Hive: Simpan ke local storage
   │
   ├─► Optimistic Update
   │   └─► emit(state.copyWith(...))
   │       └─► UI langsung update
   │
   └─► Background Sync (Jika online)
       └─► Firestore.updateHauler()
           ├─► Jika sukses: remove(queueKey)
           └─► Jika gagal: incrementRetry(queueKey)
```

#### Queue Item Types

Ada 4 jenis item yang bisa di-enqueue:

1. **event**: Status transition events
   ```dart
   QueueItemType.event
   ```

2. **telemetry**: Location, sensor data
   ```dart
   QueueItemType.telemetry
   ```

3. **haulerUpdate**: Update hauler fields
   ```dart
   QueueItemType.haulerUpdate
   ```

4. **intent**: Intent untuk server processing
   ```dart
   QueueItemType.intent
   ```

#### Queue Operations

```dart
// 1. Enqueue - Tambah item ke queue
final key = await offlineQueue.enqueue(item);

// 2. Get Pending - Ambil semua item yang belum sync
final items = await offlineQueue.getPendingItems();

// 3. Remove - Hapus item setelah sync sukses
await offlineQueue.remove(queueKey);

// 4. Increment Retry - Tambah retry count jika gagal
await offlineQueue.incrementRetry(queueKey);

// 5. Queue Size - Cek jumlah item di queue
final size = await offlineQueue.queueSize;
```

### Flow Offline-First

```
User Action
  │
  ├─► Update Local State (Optimistic)
  │   └─► emit(state.copyWith(...))
  │
  ├─► Save to Offline Queue (ALWAYS)
  │   └─► Hive: offline_queue box
  │
  └─► Try Sync to Server (Background, Non-blocking)
      │
      ├─► Jika online:
      │   ├─► Firestore operation
      │   └─► Jika sukses: Remove from queue
      │
      └─► Jika offline/gagal:
          └─► Tetap di queue, akan sync nanti
```

### Queue Item Types

1. **event**: HaulerEventEntity (status transitions)
2. **telemetry**: TelemetryEntity (location, sensor data)
3. **haulerUpdate**: Update hauler fields (status, location, bodyUp)
4. **intent**: Intent untuk server processing

---

## Connectivity & Sync Strategy

### Ping-Based Sync Strategy

Aplikasi menggunakan **ping measurement** untuk menentukan strategi sync:

```dart
PingResult.quality → SyncStrategy:
  - excellent (< 100ms)  → immediate    (Sync langsung)
  - good (100-300ms)     → batched      (Sync dalam batch, delay kecil)
  - fair (300-500ms)     → delayed      (Sync dengan delay lebih lama)
  - poor (500-1000ms)    → criticalOnly (Hanya sync critical items)
  - offline              → queue        (Tidak sync, tunggu)
```

### Connectivity Monitoring

```
ConnectivityRepository
  │
  ├─► Connectivity().onConnectivityChanged
  │   └─► Monitor perubahan koneksi (WiFi, Mobile, None)
  │
  ├─► PingService.startMonitoring()
  │   └─► Ping setiap 5 detik ke:
  │       ├─► firestore.googleapis.com
  │       ├─► firebase.google.com
  │       └─► google.com
  │
  └─► Stream<PingResult>
      └─► Update sync strategy berdasarkan ping quality
```

### Sync Flow

```
Ping Updated
  │
  └─► _handlePingBasedSync(pingResult)
      │
      ├─► immediate:
      │   └─► Cancel timer → Sync sekarang
      │
      ├─► batched/delayed:
      │   └─► Setup timer (delay berdasarkan ping)
      │       └─► Timer expires → Sync batch
      │
      ├─► criticalOnly:
      │   └─► Sync hanya:
      │       ├─► QueueItemType.event
      │       └─► QueueItemType.haulerUpdate
      │
      └─► queue:
          └─► Cancel timer, tidak sync
```

---

## State Management

### BLoC Pattern

```
Event → BLoC → State → UI
```

### HaulerBloc Events

1. **InitializeHauler**: Inisialisasi hauler saat app start
2. **UpdateLocation**: Update lokasi hauler dari GPS
3. **StartCycleEvent**: Mulai cycle baru
4. **CompleteCycleEvent**: Selesaikan cycle
5. **ToggleBodyUp / SetBodyUp**: Update body status
6. **ManualTransition**: Manual status transition (debug)
7. **ProcessAutoTransitions**: Proses auto-transition berdasarkan kondisi
8. **SelectLoader**: Pilih loader
9. **SetDumpPoint**: Set dump point location
10. **SyncOfflineData**: Force sync offline data
11. **HaulerUpdatedFromServer**: Update dari server (real-time)
12. **LoadersUpdated**: Update loaders dari Firestore

### HaulerState

```dart
HaulerState {
  String haulerId
  HaulerEntity? hauler
  HaulerStatus currentStatus
  CycleEntity? currentCycle
  List<LoaderEntity> availableLoaders
  LoaderEntity? selectedLoader
  DumpPointEntity? dumpPoint
  bool isOnline
  PingResult? pingResult
  int eventSeq
  List<String> eventLog
  bool isLoading
  bool isInitialized
  String? errorMessage
  bool serverCorrected
}
```

### State Transitions

```
STANDBY → QUEUING → SPOTTING → LOADING → HAULING_LOAD → DUMPING → HAULING_EMPTY → QUEUING (repeat)
   ↑                                                                                      │
   └──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Diagram Alur Data

### Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            USER INTERACTION                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                              │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  HomePage / Widgets                                              │  │
│  │    │                                                             │  │
│  │    ├─► User Action (Button, Gesture, dll)                        │  │
│  │    │                                                             │  │
│  │    └─► context.read<HaulerBloc>().add(Event)                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            BLoC LAYER                                   │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  HaulerBloc                                                       │  │
│  │    │                                                             │  │
│  │    ├─► Process Event                                             │  │
│  │    │   ├─► Validate                                              │  │
│  │    │   ├─► Business Logic                                        │  │
│  │    │   └─► Call Repository                                        │  │
│  │    │                                                             │  │
│  │    └─► emit(NewState)                                            │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                                    │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  HaulerRepository (Interface)                                    │  │
│  │    │                                                             │  │
│  │    ├─► getOrCreateHauler()                                       │  │
│  │    ├─► updateHauler()                                            │  │
│  │    ├─► saveEvent()                                               │  │
│  │    └─► streamHauler()                                            │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  HaulerRepositoryImpl                                             │  │
│  │    │                                                             │  │
│  │    ├─► OfflineQueue.enqueue()  ◄─── ALWAYS FIRST                │  │
│  │    │   └─► Hive: Save to local queue                            │  │
│  │    │                                                             │  │
│  │    └─► FirestoreDataSource.update()  ◄─── IF ONLINE            │  │
│  │        └─► Firestore: Update document                           │  │
│  │            └─► If success: OfflineQueue.remove()                 │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
        ┌──────────────────────┐      ┌──────────────────────┐
        │   FIREBASE FIRESTORE  │      │   HIVE (LOCAL)       │
        │                       │      │                      │
        │  - haulers/{id}       │      │  - offline_queue     │
        │  - hauler_events/{id} │      │    (Queue items)     │
        │  - cycles/{id}         │      │                      │
        │  - loaders/{id}       │      │                      │
        │  - telemetry/{id}     │      │                      │
        └──────────────────────┘      └──────────────────────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    ▼
                    ┌───────────────────────────────┐
                    │  ConnectivityRepository        │
                    │                                │
                    │  - Monitor connectivity        │
                    │  - Measure ping                │
                    │  - Determine sync strategy     │
                    │  - Process offline queue       │
                    └───────────────────────────────┘
```

### Real-time Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRESTORE REAL-TIME STREAMS                   │
└─────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Loaders     │   │  Hauler      │   │  Cycles      │
│  Stream      │   │  Stream      │   │  Stream      │
└──────────────┘   └──────────────┘   └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                ┌───────────────────────┐
                │   HaulerBloc           │
                │                        │
                │  - LoadersUpdated      │
                │  - HaulerUpdatedFrom   │
                │    Server              │
                │  - Process server      │
                │    corrections         │
                └───────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │   UI Update            │
                │   (BlocBuilder)       │
                └───────────────────────┘
```

---

## Ringkasan Alur Data

### Write Flow (Client → Server)

1. **User Action** → UI Event
2. **BLoC Event** → HaulerBloc.add(Event)
3. **Business Logic** → Validasi & proses
4. **Repository Call** → HaulerRepository.update()
5. **Queue First** → OfflineQueue.enqueue() (ALWAYS)
6. **Optimistic Update** → emit(NewState)
7. **Background Sync** → Firestore (if online)
8. **Remove from Queue** → Jika sync sukses

### Read Flow (Server → Client)

1. **Firestore Stream** → Real-time listener
2. **Repository Stream** → streamHauler(), streamLoaders()
3. **BLoC Subscription** → Listen to stream
4. **State Update** → emit(NewState)
5. **UI Update** → BlocBuilder rebuild

### Offline Sync Flow

1. **Ping Monitoring** → PingService setiap 5 detik
2. **Determine Strategy** → Berdasarkan ping quality
3. **Process Queue** → Sync items sesuai strategy
4. **Retry Failed** → Increment retry count
5. **Remove Success** → Remove dari queue

---

## Catatan Penting

1. **Offline-First**: Semua write operation selalu queue dulu, baru sync
2. **Optimistic Updates**: UI langsung update, tidak menunggu server
3. **Real-time Sync**: Server updates langsung diterima via Firestore streams
4. **Server Correction**: Jika serverSeq > localSeq, server wins
5. **Ping-Based Sync**: Strategi sync berdasarkan kualitas koneksi
6. **Retry Mechanism**: Item gagal sync akan di-retry maksimal 5 kali
7. **State Machine**: Transisi status di-validate oleh HaulerStateMachine

---

*Dokumen ini menjelaskan alur data lengkap aplikasi Hauler Truck. Untuk detail implementasi, lihat source code di masing-masing file.*

