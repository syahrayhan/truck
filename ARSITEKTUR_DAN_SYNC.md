# Arsitektur Sistem & Metode Sinkronisasi Detail

## 1. Arsitektur Layer Detail

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CLEAN ARCHITECTURE LAYERS                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      BLoC Layer                              │  │
│  │                                                               │  │
│  │  ┌──────────────┐              ┌──────────────┐             │  │
│  │  │ HaulerBloc   │              │ Simulation   │             │  │
│  │  │              │              │ Bloc         │             │  │
│  │  │ - Events     │              │              │             │  │
│  │  │ - States     │              │ - Auto move  │             │  │
│  │  │ - Logic     │              │ - Speed      │             │  │
│  │  └──────┬───────┘              └──────────────┘             │  │
│  │         │                                                     │  │
│  └─────────┼─────────────────────────────────────────────────────┘  │
│            │                                                         │
│  ┌─────────┴─────────────────────────────────────────────────────┐ │
│  │                      Widget Layer                              │ │
│  │                                                                 │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │ │
│  │  │ HaulerMap    │  │ StatusPanel  │  │ EventLog    │        │ │
│  │  │              │  │              │  │             │        │ │
│  │  │ - Map view   │  │ - Status     │  │ - Event     │        │ │
│  │  │ - Markers    │  │ - Controls   │  │   history   │        │ │
│  │  │ - Circles    │  │ - Body Up    │  │ - Debug     │        │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │ │
│  │                                                                 │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Entities                                 │  │
│  │                                                               │  │
│  │  • HaulerEntity      - Business object hauler                │  │
│  │  • CycleEntity       - Business object cycle                 │  │
│  │  • HaulerEventEntity - Business object event                 │  │
│  │  • LoaderEntity      - Business object loader                │  │
│  │  • TelemetryEntity   - Business object telemetry            │  │
│  │  • GeoLocation       - Business object location             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Use Cases                                │  │
│  │                                                               │  │
│  │  • GetOrCreateHauler    - Get or create hauler               │  │
│  │  • UpdateHaulerLocation - Update location                    │  │
│  │  • UpdateBodyUp         - Update body state                  │  │
│  │  • StartCycle           - Start new cycle                   │  │
│  │  • CompleteCycle        - Complete cycle                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Repository Interfaces                    │  │
│  │                                                               │  │
│  │  • HaulerRepository      - Abstract hauler operations        │  │
│  │  • CycleRepository       - Abstract cycle operations         │  │
│  │  • LoaderRepository      - Abstract loader operations       │  │
│  │  • LocationRepository    - Abstract location operations      │  │
│  │  • ConnectivityRepository - Abstract connectivity operations │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Models                                  │  │
│  │                                                               │  │
│  │  • HaulerModel         - DTO with serialization              │  │
│  │  • CycleModel          - DTO with serialization              │  │
│  │  • HaulerEventModel    - DTO with serialization             │  │
│  │  • LoaderModel         - DTO with serialization             │  │
│  │  • TelemetryModel      - DTO with serialization              │  │
│  │  • GeoLocationModel    - DTO with serialization             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Repository Implementations              │  │
│  │                                                               │  │
│  │  • HaulerRepositoryImpl    - Implements HaulerRepository    │  │
│  │  • CycleRepositoryImpl     - Implements CycleRepository     │  │
│  │  • LoaderRepositoryImpl    - Implements LoaderRepository    │  │
│  │  • LocationRepositoryImpl  - Implements LocationRepository │  │
│  │  • ConnectivityRepositoryImpl - Implements ConnectivityRepo│  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Data Sources                            │  │
│  │                                                               │  │
│  │  ┌────────────────────┐      ┌────────────────────┐         │  │
│  │  │ FirestoreDataSource│      │ OfflineQueue      │         │  │
│  │  │                    │      │ DataSource        │         │  │
│  │  │ - Remote operations│      │                   │         │  │
│  │  │ - Firestore API    │      │ - Hive storage   │         │  │
│  │  │ - Real-time streams│      │ - Queue management│         │  │
│  │  └────────────────────┘      └────────────────────┘         │  │
│  │                                                               │  │
│  │  ┌────────────────────┐                                      │  │
│  │  │ PingService        │                                      │  │
│  │  │                    │                                      │  │
│  │  │ - Ping measurement │                                      │  │
│  │  │ - Quality detection│                                      │  │
│  │  └────────────────────┘                                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. Metode Sinkronisasi Detail

### 2.1 Ping-Based Sync Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│              PING-BASED SYNC STRATEGY FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    PING MEASUREMENT                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [PingService]                                                      │
│         │                                                           │
│         ├───▶ Connect to firestore.googleapis.com:443             │
│         │     (Socket connection)                                  │
│         │                                                           │
│         ├───▶ Measure latency (milliseconds)                   │
│         │                                                           │
│         ├───▶ Determine quality:                                    │
│         │     • < 50ms   → Excellent                               │
│         │     • 50-150ms → Good                                    │
│         │     • 150-300ms → Fair                                   │
│         │     • 300-500ms → Poor                                   │
│         │     • > 500ms  → Offline                                 │
│         │                                                           │
│         └───▶ Emit PingResult to stream                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    SYNC STRATEGY SELECTION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  PingResult → SyncStrategy Mapping:                                 │
│                                                                     │
│  ┌─────────────┬──────────────┬──────────────┬──────────────┐     │
│  │ Quality     │ Strategy     │ Delay       │ Items        │     │
│  ├─────────────┼──────────────┼──────────────┼──────────────┤     │
│  │ Excellent   │ Immediate    │ 0ms          │ All           │     │
│  │ Good        │ Batched      │ 2000ms       │ All           │     │
│  │ Fair        │ Delayed      │ 5000ms       │ All           │     │
│  │ Poor        │ CriticalOnly │ 0ms          │ Events +      │     │
│  │             │              │              │ Updates       │     │
│  │ Offline     │ Queue        │ N/A          │ All (queued) │     │
│  └─────────────┴──────────────┴──────────────┴──────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    SYNC EXECUTION                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Strategy: IMMEDIATE                                                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ • Cancel any pending batch timers                            │ │
│  │ • Process queue immediately                                   │ │
│  │ • Sync all items in order                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Strategy: BATCHED                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ • Setup timer for 2 seconds                                │ │
│  │ • Collect items during batch window                         │ │
│  │ • Process all items when timer fires                        │ │
│  │ • Batch writes to Firestore                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Strategy: DELAYED                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ • Setup timer for 5 seconds                                │ │
│  │ • Collect items during delay window                         │ │
│  │ • Process all items when timer fires                        │ │
│  │ • Optimize for poor connection                              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Strategy: CRITICAL_ONLY                                            │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ • Filter queue for critical items only:                    │ │
│  │   - Events (status changes)                                 │ │
│  │   - Hauler updates (status, location)                       │ │
│  │ • Skip telemetry (non-critical)                            │ │
│  │ • Process critical items immediately                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Strategy: QUEUE                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ • All items queued to Hive                                 │ │
│  │ • No sync attempts                                          │ │
│  │ • Wait for connectivity restoration                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Offline Queue Mechanism

```
┌─────────────────────────────────────────────────────────────────────┐
│              OFFLINE QUEUE ARCHITECTURE                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    QUEUE STORAGE                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Storage: Hive (NoSQL database)                                     │
│  Box Name: 'offline_queue'                                         │
│                                                                     │
│  QueueItemData Structure:                                          │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ {                                                           │  │
│  │   id: String,              // Unique item ID                │  │
│  │   queueKey: String,        // Hive key                     │  │
│  │   type: QueueItemType,     // event/telemetry/intent/update │  │
│  │   data: Map,               // Item data                    │  │
│  │   createdAt: DateTime,     // Creation timestamp           │  │
│  │   retryCount: int          // Retry attempts               │  │
│  │ }                                                           │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    QUEUE OPERATIONS                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. ENQUEUE                                                         │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │ • Generate queueKey: "${type}_${id}_${timestamp}"        │  │
│     │ • Serialize data to JSON                                  │  │
│     │ • Store in Hive box                                       │  │
│     └───────────────────────────────────────────────────────────┘  │
│                                                                     │
│  2. GET PENDING ITEMS                                               │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │ • Read all items from Hive box                           │  │
│     │ • Deserialize JSON to QueueItemData                       │  │
│     │ • Sort by createdAt (oldest first)                       │  │
│     │ • Return list                                             │  │
│     └───────────────────────────────────────────────────────────┘  │
│                                                                     │
│  3. PROCESS ITEM                                                   │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │ • Check retryCount < maxRetries (5)                      │  │
│     │ • Try sync to Firestore                                   │  │
│     │ • If success: Remove from queue                           │  │
│     │ • If fail: Increment retryCount                           │  │
│     └───────────────────────────────────────────────────────────┘  │
│                                                                     │
│  4. REMOVE ITEM                                                     │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │ • Delete item from Hive box by queueKey                  │  │
│     └───────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.3 Idempotency Mechanism

```
┌─────────────────────────────────────────────────────────────────────┐
│              IDEMPOTENCY & DEDUPLICATION                            │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    DEDUPKEY GENERATION                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Format: "${haulerId}_${cycleId}_${seq}_${cause.code}"            │
│                                                                     │
│  Example:                                                          │
│  "HLR-abc123_cycle-xyz789_5_ENTERED_LOADER_RADIUS"                 │
│                                                                     │
│  Components:                                                        │
│  • haulerId: Unique hauler identifier                             │
│  • cycleId: Current cycle ID (or "no-cycle")                      │
│  • seq: Monotonic sequence number per cycle                       │
│  • cause.code: Transition cause code                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    FIRESTORE WRITE STRATEGY                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Document ID = dedupKey                                             │
│                                                                     │
│  Benefits:                                                          │
│  • Automatic deduplication (same dedupKey = same document)        │
│  • Idempotent writes (retry safe)                                 │
│  • Fast lookup by dedupKey                                         │
│                                                                     │
│  Write Options:                                                    │
│  • SetOptions(merge: true) - Merge if exists                       │
│  • Prevents overwrite of existing data                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    RETRY SCENARIO                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Scenario: Event created offline, queued, then synced              │
│                                                                     │
│  1. Event created with dedupKey: "HLR-123_cycle-456_5_T1"         │
│  2. Queued to Hive (offline)                                       │
│  3. Connection restored                                            │
│  4. Sync attempt: Write to Firestore                               │
│     • Document ID: "HLR-123_cycle-456_5_T1"                        │
│     • If exists: Merge (idempotent)                                │
│     • If new: Create                                               │
│  5. Success: Remove from queue                                     │
│                                                                     │
│  Multiple Retries:                                                  │
│  • Same dedupKey always writes to same document                    │
│  • No duplicate events created                                     │
│  • Server can validate seq for ordering                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 3. Event Sourcing Detail

### 3.1 Event Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EVENT LIFECYCLE DIAGRAM                          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 1: EVENT CREATION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Trigger: Status transition detected                               │
│                                                                     │
│  Process:                                                           │
│  1. Generate UUID for event.id                                     │
│  2. Increment eventSeq (monotonic)                                 │
│  3. Generate dedupKey                                               │
│  4. Set deviceTime (client timestamp)                              │
│  5. Collect metadata (location, bodyUp, etc.)                      │
│  6. Set synced = false                                             │
│                                                                     │
│  Result: HaulerEventEntity created                                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 2: LOCAL PERSISTENCE                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Actions:                                                           │
│  1. Update local HaulerEntity state                                │
│     • currentStatus = toStatus                                     │
│     • lastStatusChangeAt = now                                     │
│     • eventSeq = newSeq                                            │
│                                                                     │
│  2. Add step to CycleEntity                                        │
│     • Create CycleStepEntity                                       │
│     • Add to cycle.steps array                                     │
│                                                                     │
│  3. Update UI optimistically                                       │
│     • Status panel                                                 │
│     • Map markers                                                  │
│     • Event log                                                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 3: SYNC TO SERVER                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Check Connectivity:                                                │
│                                                                     │
│  ┌─────────────┐                                                   │
│  │   ONLINE    │                                                   │
│  └──────┬──────┘                                                   │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Write to Firestore                                          │  │
│  │ • Collection: hauler_events                                  │  │
│  │ • Document ID: dedupKey                                     │  │
│  │ • Data: Event model (JSON)                                  │  │
│  │ • Set serverTime: FieldValue.serverTimestamp()              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────┐                                                   │
│  │   OFFLINE   │                                                   │
│  └──────┬──────┘                                                   │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Queue to Hive                                                │  │
│  │ • Create QueueItemData                                       │  │
│  │ • Type: QueueItemType.event                                 │  │
│  │ • Store in offline_queue box                                │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 4: SERVER PROCESSING                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Cloud Function: processTelemetry / processIntent                   │
│                                                                     │
│  1. Validate Event:                                                │
│     • Check allowed transition                                     │
│     • Check guard conditions                                       │
│     • Check GPS accuracy                                           │
│                                                                     │
│  2. Apply Transition (if valid):                                   │
│     • Update hauler.currentStatus                                  │
│     • Update hauler.eventSeq                                       │
│     • Set hauler.lastStatusChangeAt                               │
│                                                                     │
│  3. Log Event:                                                      │
│     • Event already in hauler_events (idempotent)                  │
│     • Server adds serverTime                                       │
│     • Server may add metadata                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 5: CLIENT RECONCILIATION                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Firestore Stream: hauler_events updates                          │
│                                                                     │
│  1. Receive Update:                                                │
│     • Event updated in Firestore                                   │
│     • serverTime now populated                                     │
│                                                                     │
│  2. Compare States:                                                │
│     • Local event.seq vs server event.seq                         │
│     • Local hauler.status vs server hauler.status                 │
│                                                                     │
│  3. Detect Corrections:                                             │
│     • If mismatch: Server correction detected                     │
│     • Update local state to match server                          │
│     • Show correction banner in UI                                │
│                                                                     │
│  4. Update UI:                                                      │
│     • Status panel                                                 │
│     • Event log                                                   │
│     • Map markers                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Event Replay Capability

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EVENT REPLAY MECHANISM                            │
└─────────────────────────────────────────────────────────────────────┘

Scenario: Reconstruct hauler state from events

┌─────────────────────────────────────────────────────────────────────┐
│                    REPLAY PROCESS                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. Query Events:                                                   │
│     • Collection: hauler_events                                     │
│     • Filter: haulerId = "HLR-xxx"                                 │
│     • Filter: cycleId = "cycle-xxx"                                │
│     • Order: seq ASC                                                │
│                                                                     │
│  2. Replay Events:                                                  │
│     FOR each event in order:                                        │
│       • Apply transition: fromStatus → toStatus                    │
│       • Update state variables                                      │
│       • Record in cycle steps                                       │
│                                                                     │
│  3. Final State:                                                    │
│     • Current status = last event.toStatus                         │
│     • Event seq = last event.seq                                   │
│     • Cycle steps = all events as steps                            │
│                                                                     │
│  Benefits:                                                           │
│  • Audit trail                                                      │
│  • Debugging                                                        │
│  • State reconstruction                                            │
│  • Time travel (view state at any point)                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 4. Data Processing Pipeline

### 4.1 Location Processing Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│              LOCATION PROCESSING PIPELINE                            │
└─────────────────────────────────────────────────────────────────────┘

[GPS Sensor] (every 1 second)
     │
     ▼
┌─────────────────┐
│ LocationService │
│                 │
│ - Get position  │
│ - Get accuracy  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Validate GPS    │
│                 │
│ - Check accuracy│
│   ≤ 50m?        │
└────────┬────────┘
         │
         ├─── INVALID ──▶ [Skip processing] ──▶ END
         │
         ▼ VALID
┌─────────────────┐
│ Create          │
│ GeoLocation     │
│ Entity          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Local    │
│ Hauler State    │
│                 │
│ - location      │
│ - deviceTime    │
└────────┬────────┘
         │
         ├───▶ [Update UI Map]
         │
         ▼
┌─────────────────┐
│ Calculate       │
│ Distances       │
│                 │
│ - To loader     │
│ - To dump point │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Auto      │
│ Transitions     │
│                 │
│ - T1 conditions │
│ - T2 conditions │
└────────┬────────┘
         │
         ├─── NO TRANSITION ──▶ [Continue]
         │
         ▼ TRANSITION TRIGGERED
┌─────────────────┐
│ Trigger Status  │
│ Transition      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Save Telemetry  │
│                 │
│ - Create        │
│   TelemetryEntity│
│ - Save to       │
│   Firestore     │
│   (or queue)    │
└────────┬────────┘
         │
         ▼
        END
```

### 4.2 State Machine Processing

```
┌─────────────────────────────────────────────────────────────────────┐
│              STATE MACHINE PROCESSING                                │
└─────────────────────────────────────────────────────────────────────┘

[Transition Request]
     │
     ▼
┌─────────────────┐
│ Get Current     │
│ State           │
│                 │
│ - Status        │
│ - Context       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check State     │
│ Machine Rules   │
│                 │
│ - Allowed       │
│   transition?   │
└────────┬────────┘
         │
         ├─── NOT ALLOWED ──▶ [REJECT] ──▶ END
         │
         ▼ ALLOWED
┌─────────────────┐
│ Build Context   │
│                 │
│ - Location      │
│ - GPS accuracy  │
│ - Loader state  │
│ - Body state    │
│ - Dump point    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Guards    │
│                 │
│ - T1 guards     │
│ - T2 guards     │
│ - Other guards  │
└────────┬────────┘
         │
         ├─── GUARD FAIL ──▶ [REJECT] ──▶ END
         │
         ▼ GUARD PASS
┌─────────────────┐
│ Execute         │
│ Transition      │
│                 │
│ - Create event  │
│ - Update state  │
│ - Persist       │
└────────┬────────┘
         │
         ▼
        END
```

## 5. Error Handling & Recovery

### 5.1 Error Handling Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│              ERROR HANDLING MECHANISM                                │
└─────────────────────────────────────────────────────────────────────┘

Error Types:
1. Network Errors
   └───▶ Queue to offline queue, retry when online

2. Validation Errors
   └───▶ Log error, reject transition, show user message

3. GPS Errors
   └───▶ Skip transition checks, log warning

4. Firestore Errors
   └───▶ Queue for retry, exponential backoff

5. State Machine Errors
   └───▶ Reject transition, log error, show user message
```

### 5.2 Recovery Mechanisms

```
┌─────────────────────────────────────────────────────────────────────┐
│              RECOVERY MECHANISMS                                     │
└─────────────────────────────────────────────────────────────────────┘

1. Offline Recovery
   • Queue all operations
   • Sync when connectivity restored
   • Idempotent writes prevent duplicates

2. State Reconciliation
   • Compare local vs server state
   • Apply server corrections
   • Show correction notifications

3. Queue Recovery
   • Retry failed items
   • Max retry limit (5 attempts)
   • Remove items after max retries

4. Event Recovery
   • Replay events from Firestore
   • Reconstruct state
   • Validate sequence numbers
```

---

## Kesimpulan

Sistem menggunakan arsitektur yang robust dengan:

1. **Clean Architecture**: Separation of concerns, testability
2. **Offline-First**: Operasi tetap berjalan saat offline
3. **Event Sourcing**: Audit trail lengkap, replay capability
4. **Ping-Based Sync**: Optimasi berdasarkan kualitas koneksi
5. **Idempotency**: Mencegah duplikasi data
6. **Error Recovery**: Handling dan recovery mechanisms yang solid

Sistem ini dirancang untuk operasi tambang yang memerlukan reliability tinggi dan kemampuan offline yang kuat.

