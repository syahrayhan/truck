# Diagram Flowchart Detail - Hauler Truck System

## 1. Flowchart Inisialisasi Sistem

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLOWCHART INISIALISASI SISTEM                    │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Initialize      │
│ Flutter App     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Initialize      │
│ Firebase        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Initialize      │
│ Hive (Offline   │
│ Queue)          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Generate       │
│ Hauler ID      │
│ (HLR-xxxx)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Initialize      │
│ Dependency     │
│ Injection      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Initialize      │
│ HaulerBloc     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Get or Create  │
│ Hauler from    │
│ Firestore      │
└────────┬────────┘
         │
         ├─── EXISTS ──▶ [Load Hauler Data]
         │
         └─── NOT EXISTS ──▶ [Create New Hauler]
                                 │
                                 ▼
                         ┌─────────────────┐
                         │ Setup Streams   │
                         │                 │
                         │ - Loaders       │
                         │ - Connectivity  │
                         │ - Ping          │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ Initialize      │
                         │ Location        │
                         │ Service         │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ Start Ping      │
                         │ Monitoring      │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ System Ready    │
                         └────────┬────────┘
                                  │
                                  ▼
                                 END
```

## 2. Flowchart Proses Auto Transition T1

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART AUTO TRANSITION T1                               │
│          (QUEUING → SPOTTING)                                       │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Location Update │
│ Received        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Current   │
│ Status          │
└────────┬────────┘
         │
         ├─── NOT QUEUING ──▶ [SKIP] ──▶ END
         │
         ▼ QUEUING
┌─────────────────┐
│ Get Loader      │
│ Location        │
└────────┬────────┘
         │
         ├─── NO LOADER ──▶ [SKIP] ──▶ END
         │
         ▼ HAS LOADER
┌─────────────────┐
│ Calculate       │
│ Distance to     │
│ Loader          │
└────────┬────────┘
         │
         ├─── Distance > 50m ──▶ [SKIP] ──▶ END
         │
         ▼ Distance ≤ 50m
┌─────────────────┐
│ Check GPS       │
│ Accuracy        │
└────────┬────────┘
         │
         ├─── Accuracy > 50m ──▶ [SKIP] ──▶ END
         │
         ▼ Accuracy ≤ 50m
┌─────────────────┐
│ Check Loader    │
│ waitingTruck    │
└────────┬────────┘
         │
         ├─── NOT WAITING ──▶ [SKIP] ──▶ END
         │
         ▼ WAITING
┌─────────────────┐
│ All Conditions  │
│ Met             │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create Event    │
│                 │
│ - fromStatus:   │
│   QUEUING       │
│ - toStatus:     │
│   SPOTTING      │
│ - cause:        │
│   ENTERED_      │
│   LOADER_RADIUS │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Local    │
│ State           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Save Event      │
│ (Online/Offline)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update UI       │
└────────┬────────┘
         │
         ▼
        END
```

## 3. Flowchart Proses Auto Transition T2

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART AUTO TRANSITION T2                               │
│          (HAULING_LOAD → DUMPING)                                   │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Location Update │
│ OR Body Up      │
│ Toggle          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Current   │
│ Status          │
└────────┬────────┘
         │
         ├─── NOT HAULING_LOAD ──▶ [SKIP] ──▶ END
         │
         ▼ HAULING_LOAD
┌─────────────────┐
│ Check Body Up   │
│ State           │
└────────┬────────┘
         │
         ├─── NOT UP ──▶ [SKIP] ──▶ END
         │
         ▼ BODY UP
┌─────────────────┐
│ Get Dump Point  │
│ Location        │
└────────┬────────┘
         │
         ├─── NO DUMP POINT ──▶ [SKIP] ──▶ END
         │
         ▼ HAS DUMP POINT
┌─────────────────┐
│ Calculate       │
│ Distance to     │
│ Dump Point      │
└────────┬────────┘
         │
         ├─── Distance > 40m ──▶ [SKIP] ──▶ END
         │
         ▼ Distance ≤ 40m
┌─────────────────┐
│ Check GPS       │
│ Accuracy        │
└────────┬────────┘
         │
         ├─── Accuracy > 50m ──▶ [SKIP] ──▶ END
         │
         ▼ Accuracy ≤ 50m
┌─────────────────┐
│ All Conditions  │
│ Met             │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create Event    │
│                 │
│ - fromStatus:   │
│   HAULING_LOAD  │
│ - toStatus:     │
│   DUMPING       │
│ - cause: BODY_UP│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Local    │
│ State           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Save Event      │
│ (Online/Offline)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update UI       │
└────────┬────────┘
         │
         ▼
        END
```

## 4. Flowchart Sinkronisasi Offline Queue

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART SINKRONISASI OFFLINE QUEUE                       │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Connectivity    │
│ Changed         │
└────────┬────────┘
         │
         ├─── OFFLINE ──▶ [Queue Items] ──▶ END
         │
         ▼ ONLINE
┌─────────────────┐
│ Measure Ping    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Determine Sync  │
│ Strategy        │
└────────┬────────┘
         │
         ├─── IMMEDIATE ──▶ [Process Queue Now]
         │
         ├─── BATCHED ──▶ [Setup Timer 2s]
         │
         ├─── DELAYED ──▶ [Setup Timer 5s]
         │
         ├─── CRITICAL_ONLY ──▶ [Process Critical Items]
         │
         └─── QUEUE ──▶ [Wait] ──▶ END
         │
         ▼ (Timer Fired or Immediate)
┌─────────────────┐
│ Get Pending     │
│ Queue Items     │
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
         ├─── Retry > Max ──▶ [Remove Item] ──▶ [Next Item]
         │
         ▼ Retry ≤ Max
┌─────────────────┐
│ Try Sync Item   │
│ to Firestore    │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove Item] ──▶ [Next Item]
         │
         └─── FAIL ──▶ [Increment Retry] ──▶ [Next Item]
         │
         ▼ (All Items Processed)
┌─────────────────┐
│ Sync Complete   │
└────────┬────────┘
         │
         ▼
        END
```

## 5. Flowchart Server Processing

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART SERVER PROCESSING                                │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    TELEMETRY PROCESSING                              │
└─────────────────────────────────────────────────────────────────────┘

[Telemetry Created in Firestore]
         │
         ▼
┌─────────────────┐
│ Cloud Function  │
│ Triggered       │
│ (processTelemetry)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Get Hauler      │
│ Document        │
└────────┬────────┘
         │
         ├─── NOT FOUND ──▶ [SKIP] ──▶ END
         │
         ▼ FOUND
┌─────────────────┐
│ Update Hauler   │
│ Location        │
│                 │
│ - lat, lng      │
│ - accuracy      │
│ - bodyUp        │
│ - online: true  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Auto      │
│ Transitions     │
│                 │
│ - T1: HAULING_  │
│   EMPTY →       │
│   QUEUING       │
│                 │
│ - T2: HAULING_  │
│   LOAD →        │
│   DUMPING       │
└────────┬────────┘
         │
         ├─── NO TRANSITION ──▶ [END]
         │
         ▼ TRANSITION TRIGGERED
┌─────────────────┐
│ Create Event    │
│                 │
│ - Generate      │
│   dedupKey      │
│ - Increment seq │
│ - Set serverTime│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Hauler   │
│ Status          │
└────────┬────────┘
         │
         ▼
        END

┌─────────────────────────────────────────────────────────────────────┐
│                    INTENT PROCESSING                                │
└─────────────────────────────────────────────────────────────────────┘

[Intent Created in Firestore]
         │
         ▼
┌─────────────────┐
│ Cloud Function  │
│ Triggered       │
│ (processIntent) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Get Hauler,     │
│ Cycle, Loader   │
│ Data            │
└────────┬────────┘
         │
         ├─── NOT FOUND ──▶ [Mark Intent Failed] ──▶ END
         │
         ▼ FOUND
┌─────────────────┐
│ Validate        │
│ Transition      │
│                 │
│ - Check allowed │
│   transitions    │
│ - Check guard   │
│   conditions     │
│ - Check GPS     │
│   accuracy      │
└────────┬────────┘
         │
         ├─── INVALID ──▶ [Mark Intent Failed] ──▶ END
         │
         ▼ VALID
┌─────────────────┐
│ Create Event    │
│                 │
│ - Generate      │
│   dedupKey      │
│ - Increment seq │
│ - Set serverTime│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Hauler   │
│ Status          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Mark Intent     │
│ Processed       │
│ (success)       │
└────────┬────────┘
         │
         ▼
        END
```

## 6. Flowchart Rekonsiliasi State

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART REKONSILIASI STATE                               │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Firestore Stream│
│ Update Received │
│ (Hauler Status) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Get Local State │
│ (from BLoC)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Compare States  │
│                 │
│ - Status        │
│ - Event Seq     │
│ - Timestamp     │
└────────┬────────┘
         │
         ├─── MATCH ──▶ [No Action] ──▶ END
         │
         ▼ MISMATCH
┌─────────────────┐
│ Check Which is  │
│ Newer           │
└────────┬────────┘
         │
         ├─── SERVER NEWER ──▶ [Server Correction]
         │                          │
         │                          ▼
         │                  ┌─────────────────┐
         │                  │ Update Local    │
         │                  │ State           │
         │                  └────────┬────────┘
         │                           │
         │                           ▼
         │                  ┌─────────────────┐
         │                  │ Show Correction │
         │                  │ Banner          │
         │                  └────────┬────────┘
         │                           │
         │                           ▼
         │                          END
         │
         └─── LOCAL NEWER ──▶ [Pending Sync]
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ Check if in     │
                         │ Offline Queue   │
                         └────────┬────────┘
                                  │
                                  ├─── YES ──▶ [Wait for Sync] ──▶ END
                                  │
                                  └─── NO ──▶ [Log Warning] ──▶ END
```

## 7. Flowchart Cycle Management

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART CYCLE MANAGEMENT                                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    START CYCLE                                      │
└─────────────────────────────────────────────────────────────────────┘

[User Clicks Start Cycle]
         │
         ▼
┌─────────────────┐
│ Validate        │
│ Prerequisites   │
│                 │
│ - Loader        │
│   selected?     │
│ - Dump point    │
│   set?          │
│ - Status =      │
│   STANDBY?      │
└────────┬────────┘
         │
         ├─── INVALID ──▶ [Show Error] ──▶ END
         │
         ▼ VALID
┌─────────────────┐
│ Generate Cycle  │
│ ID (UUID)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create Cycle    │
│ Entity          │
│                 │
│ - id            │
│ - haulerId      │
│ - loaderId      │
│ - loaderLocation│
│ - dumpLocation  │
│ - steps: []     │
│ - completed:    │
│   false         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Save Cycle to   │
│ Firestore       │
└────────┬────────┘
         │
         ├─── FAIL ──▶ [Queue for Retry] ──▶ END
         │
         ▼ SUCCESS
┌─────────────────┐
│ Update Local    │
│ State           │
│                 │
│ - currentCycle  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Transition to   │
│ QUEUING         │
└────────┬────────┘
         │
         ▼
        END

┌─────────────────────────────────────────────────────────────────────┐
│                    UPDATE CYCLE                                     │
└─────────────────────────────────────────────────────────────────────┘

[Status Transition]
         │
         ▼
┌─────────────────┐
│ Create Cycle    │
│ Step            │
│                 │
│ - status        │
│ - timestamp     │
│ - location      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Add Step to    │
│ Cycle           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Cycle in │
│ Firestore       │
└────────┬────────┘
         │
         ▼
        END

┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE CYCLE                                    │
└─────────────────────────────────────────────────────────────────────┘

[Cycle Complete Triggered]
         │
         ▼
┌─────────────────┐
│ Mark Cycle      │
│ Complete        │
│                 │
│ - completed:    │
│   true          │
│ - completedAt:  │
│   now           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Cycle in │
│ Firestore       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Transition to   │
│ STANDBY         │
└────────┬────────┘
         │
         ▼
        END
```

## 8. Flowchart Ping Monitoring

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART PING MONITORING                                   │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Start Ping      │
│ Monitoring      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Setup Timer     │
│ (Every 5s)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ FOR each host:  │
│                 │
│ - firestore.    │
│   googleapis.   │
│   com           │
│ - firebase.     │
│   google.com    │
│ - google.com    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Connect Socket  │
│ (Port 443)      │
└────────┬────────┘
         │
         ├─── TIMEOUT ──▶ [Try Next Host]
         │
         ├─── ERROR ──▶ [Try Next Host]
         │
         ▼ SUCCESS
┌─────────────────┐
│ Measure Latency │
│ (ping time)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Determine       │
│ Quality         │
│                 │
│ < 50ms:         │
│   Excellent     │
│ 50-150ms:       │
│   Good          │
│ 150-300ms:      │
│   Fair          │
│ 300-500ms:      │
│   Poor          │
│ > 500ms:        │
│   Offline       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Determine Sync  │
│ Strategy        │
│                 │
│ Excellent:      │
│   Immediate     │
│ Good: Batched   │
│ Fair: Delayed   │
│ Poor: Critical  │
│   Only          │
│ Offline: Queue  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Emit Ping Result│
│ to Stream       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Wait for Next   │
│ Interval        │
└────────┬────────┘
         │
         └───▶ [Loop Back]
```

## 9. Flowchart Proses Location Data (GPS → Server)

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART PROSES LOCATION DATA                             │
│          (GPS Sensor → Firestore Server)                            │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ GPS Sensor      │
│ (Hardware)      │
│                 │
│ - Get position  │
│ - Get accuracy  │
│ - Get timestamp │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ LocationService │
│ (geolocator)    │
│                 │
│ - Request       │
│   position      │
│ - Handle        │
│   permissions   │
└────────┬────────┘
         │
         ├─── PERMISSION DENIED ──▶ [Request Permission] ──▶ END
         │
         ▼ PERMISSION GRANTED
┌─────────────────┐
│ Get Position     │
│ Data             │
│                 │
│ - latitude       │
│ - longitude      │
│ - accuracy       │
│ - timestamp      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Validate GPS    │
│ Data            │
│                 │
│ - Check if      │
│   valid coords  │
│ - Check accuracy│
│   ≤ 50m?        │
└────────┬────────┘
         │
         ├─── INVALID ──▶ [Skip Processing] ──▶ END
         │
         ▼ VALID
┌─────────────────┐
│ Create          │
│ GeoLocation      │
│ Entity          │
│                 │
│ - lat, lng      │
│ - accuracy      │
│ - timestamp     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Location        │
│ Repository      │
│ (Domain Layer)  │
│                 │
│ - Receive       │
│   location      │
│   entity        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ HaulerBloc      │
│ onUpdateLocation│
│                 │
│ - Update local  │
│   hauler state  │
│ - Trigger auto  │
│   transitions   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hauler          │
│ Repository      │
│ updateLocation  │
│                 │
│ - Convert entity│
│   to model      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check            │
│ Connectivity     │
└────────┬────────┘
         │
         ├─── ONLINE ──▶ [Path A: Direct Save]
         │
         └─── OFFLINE ──▶ [Path B: Queue for Later]
         │
         ▼ [Path A: ONLINE]
┌─────────────────┐
│ Firestore       │
│ Data Source      │
│ updateHauler     │
│                 │
│ - Prepare data  │
│   map           │
│ - Add deviceTime│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore API   │
│ Write            │
│                 │
│ collection:     │
│   haulers       │
│ document:       │
│   {haulerId}    │
│ operation:      │
│   update()      │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Update UI] ──▶ END
         │
         └─── FAIL ──▶ [Queue to Offline Queue] ──▶ [Path B]
         │
         ▼ [Path B: OFFLINE / FAILED]
┌─────────────────┐
│ Offline Queue   │
│ Data Source      │
│                 │
│ - Create        │
│   QueueItemData │
│ - Type:         │
│   haulerUpdate  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hive Storage    │
│                 │
│ - Serialize to  │
│   JSON          │
│ - Store in box: │
│   offline_queue │
│ - Generate      │
│   queueKey      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update UI       │
│ Optimistically  │
│                 │
│ - Show location │
│   on map        │
│ - Update status │
│   panel         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Wait for        │
│ Connectivity    │
│                 │
│ - Monitor ping  │
│ - Check network │
└────────┬────────┘
         │
         ▼ [When Online]
┌─────────────────┐
│ Sync Offline     │
│ Queue            │
│                 │
│ - Get pending   │
│   items         │
│ - Process queue  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore       │
│ Write (Retry)    │
│                 │
│ - Same process  │
│   as Path A     │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ END
         │
         └─── FAIL ──▶ [Increment Retry Count]
                      │
                      ├─── Retry < Max ──▶ [Retry Later] ──▶ END
                      │
                      └─── Retry ≥ Max ──▶ [Remove Item] ──▶ END
```

## 10. Flowchart Proses Event Data (Trigger → Server)

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART PROSES EVENT DATA                               │
│          (Status Transition → Firestore Server)                     │
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
│ Status          │
│                 │
│ - Get current   │
│   status        │
│ - Get new       │
│   status        │
│ - Get cause     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Generate Event  │
│ Data            │
│                 │
│ - Generate UUID │
│ - Increment seq │
│ - Create        │
│   dedupKey      │
│ - Set deviceTime│
│ - Collect       │
│   metadata      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create          │
│ HaulerEvent     │
│ Entity          │
│                 │
│ - id            │
│ - haulerId      │
│ - cycleId       │
│ - fromStatus    │
│ - toStatus      │
│ - cause         │
│ - seq           │
│ - dedupKey      │
│ - deviceTime    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Local    │
│ State           │
│                 │
│ - Hauler status │
│ - Cycle steps   │
│ - Event seq     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hauler          │
│ Repository      │
│ saveEvent       │
│                 │
│ - Convert entity│
│   to model      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check            │
│ Connectivity     │
└────────┬────────┘
         │
         ├─── ONLINE ──▶ [Path A: Direct Save]
         │
         └─── OFFLINE ──▶ [Path B: Queue for Later]
         │
         ▼ [Path A: ONLINE]
┌─────────────────┐
│ Firestore       │
│ Data Source      │
│ saveEvent        │
│                 │
│ - Convert model │
│   to map        │
│ - Add serverTime │
│   (server       │
│   timestamp)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore API   │
│ Write            │
│                 │
│ collection:     │
│   hauler_events │
│ document ID:     │
│   {dedupKey}    │
│ operation:      │
│   set(merge:true)│
│                 │
│ Note: dedupKey  │
│ as doc ID       │
│ ensures         │
│ idempotency     │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Update UI] ──▶ END
         │
         └─── FAIL ──▶ [Queue to Offline Queue] ──▶ [Path B]
         │
         ▼ [Path B: OFFLINE / FAILED]
┌─────────────────┐
│ Offline Queue   │
│ Data Source      │
│                 │
│ - Create        │
│   QueueItemData │
│ - Type: event   │
│ - Store event   │
│   data          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hive Storage    │
│                 │
│ - Serialize     │
│   event to JSON │
│ - Store in box: │
│   offline_queue │
│ - Generate      │
│   queueKey      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update UI       │
│ Optimistically  │
│                 │
│ - Show new      │
│   status        │
│ - Update event  │
│   log           │
│ - Update map    │
│   markers       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Wait for        │
│ Connectivity    │
└────────┬────────┘
         │
         ▼ [When Online]
┌─────────────────┐
│ Sync Offline     │
│ Queue            │
│                 │
│ - Get event      │
│   items          │
│ - Process in     │
│   order          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore       │
│ Write (Retry)    │
│                 │
│ - Same dedupKey │
│   as doc ID     │
│ - Idempotent    │
│   write         │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ END
         │
         └─── FAIL ──▶ [Increment Retry Count]
                      │
                      ├─── Retry < Max ──▶ [Retry Later] ──▶ END
                      │
                      └─── Retry ≥ Max ──▶ [Remove Item] ──▶ END
```

## 11. Flowchart Proses Telemetry Data (Sensor → Server)

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART PROSES TELEMETRY DATA                           │
│          (GPS + Sensor → Firestore Server)                         │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ Data Sources    │
│                 │
│ - GPS Location  │
│ - Body Sensor   │
│ - Timestamp     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Collect         │
│ Telemetry Data  │
│                 │
│ - lat, lng      │
│ - accuracy      │
│ - bodyUp        │
│ - deviceTime    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create          │
│ Telemetry       │
│ Entity          │
│                 │
│ - Generate UUID │
│ - haulerId      │
│ - cycleId       │
│ - location      │
│ - bodyUp        │
│ - deviceTime    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hauler          │
│ Repository      │
│ saveTelemetry   │
│                 │
│ - Convert entity│
│   to model      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check            │
│ Connectivity     │
└────────┬────────┘
         │
         ├─── ONLINE ──▶ [Path A: Direct Save]
         │
         └─── OFFLINE ──▶ [Path B: Queue for Later]
         │
         ▼ [Path A: ONLINE]
┌─────────────────┐
│ Firestore       │
│ Data Source      │
│ saveTelemetry    │
│                 │
│ - Convert model │
│   to map        │
│ - Add createdAt │
│   (server       │
│   timestamp)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore API   │
│ Write            │
│                 │
│ collection:     │
│   telemetry     │
│ document ID:     │
│   {telemetryId} │
│ operation:      │
│   set()         │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Trigger Cloud Function] ──▶ END
         │
         └─── FAIL ──▶ [Queue to Offline Queue] ──▶ [Path B]
         │
         ▼ [Cloud Function Triggered]
┌─────────────────┐
│ processTelemetry│
│ (Server)        │
│                 │
│ - Update hauler │
│   location      │
│ - Check auto    │
│   transitions   │
└────────┬────────┘
         │
         ▼
        END
         │
         ▼ [Path B: OFFLINE / FAILED]
┌─────────────────┐
│ Offline Queue   │
│ Data Source      │
│                 │
│ - Create        │
│   QueueItemData │
│ - Type:         │
│   telemetry     │
│ - Store data    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hive Storage    │
│                 │
│ - Serialize to  │
│   JSON          │
│ - Store in box: │
│   offline_queue │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Wait for        │
│ Connectivity    │
└────────┬────────┘
         │
         ▼ [When Online]
┌─────────────────┐
│ Sync Offline     │
│ Queue            │
│                 │
│ - Get telemetry │
│   items          │
│ - Process batch │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore       │
│ Write (Retry)    │
│                 │
│ - Same process  │
│   as Path A     │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ END
         │
         └─── FAIL ──▶ [Increment Retry Count]
                      │
                      ├─── Retry < Max ──▶ [Retry Later] ──▶ END
                      │
                      └─── Retry ≥ Max ──▶ [Remove Item] ──▶ END
```

## 12. Flowchart Proses Cycle Data (User Action → Server)

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART PROSES CYCLE DATA                                │
│          (User Action → Firestore Server)                            │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────┐
│ User Action     │
│                 │
│ - Start Cycle   │
│ - Complete      │
│   Cycle         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ HaulerBloc      │
│ Event Handler   │
│                 │
│ - Validate      │
│   prerequisites │
│ - Get loader    │
│ - Get dump point│
└────────┬────────┘
         │
         ├─── INVALID ──▶ [Show Error] ──▶ END
         │
         ▼ VALID
┌─────────────────┐
│ Create Cycle    │
│ Entity          │
│                 │
│ - Generate UUID │
│ - haulerId      │
│ - loaderId      │
│ - loaderLocation│
│ - dumpLocation  │
│ - steps: []      │
│ - completed:    │
│   false         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Cycle            │
│ Repository      │
│ createCycle /    │
│ updateCycle      │
│                 │
│ - Convert entity│
│   to model      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check            │
│ Connectivity     │
└────────┬────────┘
         │
         ├─── ONLINE ──▶ [Path A: Direct Save]
         │
         └─── OFFLINE ──▶ [Path B: Queue for Later]
         │
         ▼ [Path A: ONLINE]
┌─────────────────┐
│ Firestore       │
│ Data Source      │
│ createCycle /    │
│ updateCycle      │
│                 │
│ - Convert model │
│   to map        │
│ - Prepare data  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore API   │
│ Write            │
│                 │
│ collection:     │
│   cycles        │
│ document ID:     │
│   {cycleId}     │
│ operation:      │
│   set() /       │
│   update()      │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Update Local State] ──▶ [Update UI] ──▶ END
         │
         └─── FAIL ──▶ [Queue to Offline Queue] ──▶ [Path B]
         │
         ▼ [Path B: OFFLINE / FAILED]
┌─────────────────┐
│ Offline Queue   │
│ Data Source      │
│                 │
│ - Create        │
│   QueueItemData │
│ - Type: cycle   │
│ - Store cycle   │
│   data          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hive Storage    │
│                 │
│ - Serialize to  │
│   JSON          │
│ - Store in box: │
│   offline_queue │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update UI       │
│ Optimistically  │
│                 │
│ - Show cycle    │
│   started       │
│ - Update status │
│   panel         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Wait for        │
│ Connectivity    │
└────────┬────────┘
         │
         ▼ [When Online]
┌─────────────────┐
│ Sync Offline     │
│ Queue            │
│                 │
│ - Get cycle      │
│   items          │
│ - Process        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firestore       │
│ Write (Retry)    │
│                 │
│ - Same process  │
│   as Path A     │
└────────┬────────┘
         │
         ├─── SUCCESS ──▶ [Remove from Queue] ──▶ END
         │
         └─── FAIL ──▶ [Increment Retry Count]
                      │
                      ├─── Retry < Max ──▶ [Retry Later] ──▶ END
                      │
                      └─── Retry ≥ Max ──▶ [Remove Item] ──▶ END
```

## 13. Flowchart Lengkap: Data Flow dari Sensor hingga Server

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOWCHART LENGKAP DATA FLOW                                │
│          (Sensor → Processing → Storage → Server)                    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 1: DATA ACQUISITION                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ GPS Sensor  │  │ Body Sensor  │  │ User Input   │            │
│  │             │  │              │  │              │            │
│  │ - lat, lng  │  │ - bodyUp     │  │ - Start      │            │
│  │ - accuracy  │  │ - bodyDown   │  │   Cycle      │            │
│  │ - timestamp │  │ - timestamp  │  │ - Manual     │            │
│  └──────┬───────┘  └──────┬───────┘  │   Transition│            │
│         │                 │          └──────┬───────┘            │
│         └─────────────────┴─────────────────┘                    │
│                            │                                      │
└────────────────────────────┼──────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 2: DATA VALIDATION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Validate Data                                                │  │
│  │                                                              │  │
│  │ - GPS coordinates valid?                                     │  │
│  │ - GPS accuracy ≤ 50m?                                       │  │
│  │ - Sensor data valid?                                         │  │
│  │ - User input valid?                                          │  │
│  │ - Prerequisites met?                                          │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
│                     ├─── INVALID ──▶ [Reject] ──▶ END              │
│                     │                                               │
│                     ▼ VALID                                         │
└─────────────────────┼───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 3: ENTITY CREATION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ GeoLocation  │  │ HaulerEvent  │  │ Cycle        │            │
│  │ Entity       │  │ Entity       │  │ Entity       │            │
│  │              │  │              │  │              │            │
│  │ - lat, lng   │  │ - id, seq    │  │ - id         │            │
│  │ - accuracy   │  │ - dedupKey   │  │ - steps       │            │
│  │ - timestamp  │  │ - status     │  │ - completed  │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                 │                 │                     │
│         └─────────────────┴─────────────────┘                    │
│                            │                                      │
└────────────────────────────┼──────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 4: BUSINESS LOGIC                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ HaulerBloc Processing                                         │  │
│  │                                                               │  │
│  │ - Update local state                                          │  │
│  │ - Process auto transitions                                    │  │
│  │ - Validate state machine                                      │  │
│  │ - Check guard conditions                                      │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
└─────────────────────┼───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 5: REPOSITORY LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ Hauler       │  │ Cycle        │  │ Location     │            │
│  │ Repository   │  │ Repository   │  │ Repository   │            │
│  │              │  │              │  │              │            │
│  │ - Convert    │  │ - Convert    │  │ - Convert    │            │
│  │   entity to  │  │   entity to  │  │   entity to  │            │
│  │   model      │  │   model      │  │   model      │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                 │                 │                     │
│         └─────────────────┴─────────────────┘                    │
│                            │                                      │
└────────────────────────────┼──────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 6: CONNECTIVITY CHECK                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Check Connectivity                                            │  │
│  │                                                               │  │
│  │ - Ping measurement                                            │  │
│  │ - Network status                                              │  │
│  │ - Determine sync strategy                                     │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
│                     ├─── ONLINE ──▶ [Path A: Direct Save]          │
│                     │                                               │
│                     └─── OFFLINE ──▶ [Path B: Queue]                │
│                                                                     │
└─────────────────────┼───────────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
┌───────────────────┐      ┌───────────────────┐
│ PATH A: ONLINE    │      │ PATH B: OFFLINE    │
│                   │      │                    │
│ Firestore Data    │      │ Offline Queue      │
│ Source            │      │ Data Source         │
│                   │      │                    │
│ - Convert model   │      │ - Create           │
│   to map         │      │   QueueItemData    │
│ - Add timestamps │      │ - Store in Hive    │
└────────┬──────────┘      └────────┬──────────┘
         │                          │
         ▼                          ▼
┌───────────────────┐      ┌───────────────────┐
│ Firestore API     │      │ Hive Storage      │
│                   │      │                   │
│ - Write to        │      │ - Serialize JSON  │
│   collection      │      │ - Store in box    │
│ - Use dedupKey    │      │ - Generate key   │
│   for events      │      └────────┬──────────┘
└────────┬──────────┘               │
         │                          │
         ├─── SUCCESS ──▶ [Update UI] ──▶ END
         │                          │
         └─── FAIL ──▶ [Queue] ──────┘
                      │
                      ▼
              [Wait for Connectivity]
                      │
                      ▼
              [Sync Queue when Online]
                      │
                      ▼
              [Retry Firestore Write]
                      │
                      ├─── SUCCESS ──▶ [Remove from Queue] ──▶ END
                      │
                      └─── FAIL ──▶ [Increment Retry]
                                   │
                                   ├─── Retry < Max ──▶ [Retry Later]
                                   │
                                   └─── Retry ≥ Max ──▶ [Remove Item]
```

---

## Simbol Flowchart

- **Persegi Panjang**: Proses/Operasi
- **Diamond**: Keputusan/Conditional
- **Paralelogram**: Input/Output
- **Oval**: Start/End
- **Panah**: Alur proses

---

## Catatan Penting

1. **Error Handling**: Semua proses memiliki error handling yang tidak ditampilkan untuk kesederhanaan
2. **Retry Logic**: Semua operasi network memiliki retry mechanism
3. **Idempotency**: Semua writes menggunakan dedupKey untuk idempotency
4. **Optimistic Updates**: UI selalu update optimistically, kemudian reconcile dengan server

