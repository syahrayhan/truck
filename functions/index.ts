/**
 * Cloud Functions for Hauler Truck Mining Operations
 * 
 * Server-side arbiter for status transitions and event processing.
 * The server is the single source of truth for status - clients only send
 * intents and telemetry, never set status directly.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Types
interface GeoLocation {
  lat: number;
  lng: number;
  accuracy?: number;
}

interface Intent {
  haulerId: string;
  cycleId: string;
  type: string;
  requestedStatus?: string;
  deviceTime: string;
  location?: GeoLocation;
  context?: Record<string, any>;
  processed: boolean;
  resultEventId?: string;
}

interface Hauler {
  currentStatus: string;
  lastStatusChangeAt: string;
  location?: GeoLocation;
  bodyUp: boolean;
  online: boolean;
  deviceTime: string;
  cycleId?: string;
  assignedLoaderId?: string;
  eventSeq: number;
}

interface Loader {
  location: GeoLocation;
  waitingTruck: boolean;
  radius: number;
}

interface Cycle {
  haulerId: string;
  loaderId?: string;
  loaderLocation?: GeoLocation;
  dumpLocation?: GeoLocation;
  dumpRadius: number;
  completed: boolean;
}

// Constants
const LOADER_RADIUS = 50; // meters
const DUMP_RADIUS = 40; // meters
const GPS_ACCURACY_THRESHOLD = 50; // meters

// Allowed transitions
const ALLOWED_TRANSITIONS: Record<string, string[]> = {
  'STANDBY': ['QUEUING'],
  'QUEUING': ['SPOTTING', 'STANDBY'],
  'SPOTTING': ['LOADING', 'QUEUING', 'STANDBY'],
  'LOADING': ['HAULING_LOAD', 'STANDBY'],
  'HAULING_LOAD': ['DUMPING', 'STANDBY'],
  'DUMPING': ['HAULING_EMPTY', 'STANDBY'],
  'HAULING_EMPTY': ['QUEUING', 'STANDBY'],
};

/**
 * Process intent from client
 * Validates and applies status transitions based on rules
 */
export const processIntent = functions.firestore
  .document('intents/{intentId}')
  .onCreate(async (snapshot, context) => {
    const intent = snapshot.data() as Intent;
    const intentId = context.params.intentId;
    
    try {
      // Get hauler document
      const haulerRef = db.collection('haulers').doc(intent.haulerId);
      const haulerDoc = await haulerRef.get();
      
      if (!haulerDoc.exists) {
        await markIntentProcessed(intentId, false, 'Hauler not found');
        return;
      }
      
      const hauler = haulerDoc.data() as Hauler;
      
      // Get cycle and loader if available
      let cycle: Cycle | null = null;
      let loader: Loader | null = null;
      
      if (intent.cycleId) {
        const cycleDoc = await db.collection('cycles').doc(intent.cycleId).get();
        cycle = cycleDoc.data() as Cycle || null;
        
        if (cycle?.loaderId) {
          const loaderDoc = await db.collection('loaders').doc(cycle.loaderId).get();
          loader = loaderDoc.data() as Loader || null;
        }
      }
      
      // Validate transition
      const validation = validateTransition(
        intent,
        hauler,
        cycle,
        loader
      );
      
      if (!validation.valid) {
        await markIntentProcessed(intentId, false, validation.reason);
        return;
      }
      
      // Apply transition
      const newSeq = hauler.eventSeq + 1;
      const now = admin.firestore.Timestamp.now();
      
      // Create event
      const eventId = `${intent.haulerId}_${intent.cycleId}_${newSeq}_${intent.type}`;
      await db.collection('hauler_events').doc(eventId).set({
        haulerId: intent.haulerId,
        cycleId: intent.cycleId,
        fromStatus: hauler.currentStatus,
        toStatus: intent.requestedStatus,
        cause: intent.type,
        deviceTime: intent.deviceTime,
        serverTime: now,
        seq: newSeq,
        dedupKey: eventId,
        synced: true,
      });
      
      // Update hauler status
      await haulerRef.update({
        currentStatus: intent.requestedStatus,
        lastStatusChangeAt: now,
        eventSeq: newSeq,
      });
      
      // Mark intent as processed
      await markIntentProcessed(intentId, true, undefined, eventId);
      
      console.log(`Processed intent ${intentId}: ${hauler.currentStatus} -> ${intent.requestedStatus}`);
      
    } catch (error) {
      console.error('Error processing intent:', error);
      await markIntentProcessed(intentId, false, 'Internal error');
    }
  });

/**
 * Process telemetry and check for automatic transitions
 */
export const processTelemetry = functions.firestore
  .document('telemetry/{telemetryId}')
  .onCreate(async (snapshot) => {
    const telemetry = snapshot.data();
    
    try {
      const haulerRef = db.collection('haulers').doc(telemetry.haulerId);
      const haulerDoc = await haulerRef.get();
      
      if (!haulerDoc.exists) return;
      
      const hauler = haulerDoc.data() as Hauler;
      
      // Update hauler location
      await haulerRef.update({
        location: {
          lat: telemetry.lat,
          lng: telemetry.lng,
          accuracy: telemetry.accuracy,
        },
        bodyUp: telemetry.bodyUp,
        online: true,
        deviceTime: telemetry.deviceTime,
      });
      
      // Check for automatic transitions
      await checkAutoTransitions(
        telemetry.haulerId,
        hauler,
        telemetry,
      );
      
    } catch (error) {
      console.error('Error processing telemetry:', error);
    }
  });

/**
 * Validate status transition
 */
function validateTransition(
  intent: Intent,
  hauler: Hauler,
  cycle: Cycle | null,
  loader: Loader | null
): { valid: boolean; reason?: string } {
  
  const currentStatus = hauler.currentStatus;
  const targetStatus = intent.requestedStatus;
  
  if (!targetStatus) {
    return { valid: false, reason: 'No target status specified' };
  }
  
  // Check if transition is allowed
  const allowed = ALLOWED_TRANSITIONS[currentStatus] || [];
  if (!allowed.includes(targetStatus)) {
    return { 
      valid: false, 
      reason: `Transition from ${currentStatus} to ${targetStatus} not allowed` 
    };
  }
  
  // Check guard conditions
  const location = intent.location || hauler.location;
  
  // T1: QUEUING -> SPOTTING
  if (currentStatus === 'QUEUING' && targetStatus === 'SPOTTING') {
    if (!loader?.waitingTruck) {
      return { valid: false, reason: 'Loader not waiting for truck' };
    }
    if (location && loader) {
      const distance = calculateDistance(location, loader.location);
      if (distance > (loader.radius || LOADER_RADIUS)) {
        return { valid: false, reason: 'Hauler not in loader radius' };
      }
    }
    if (location?.accuracy && location.accuracy > GPS_ACCURACY_THRESHOLD) {
      return { valid: false, reason: 'GPS accuracy too low' };
    }
  }
  
  // T2: HAULING_LOAD -> DUMPING
  if (currentStatus === 'HAULING_LOAD' && targetStatus === 'DUMPING') {
    if (!hauler.bodyUp) {
      return { valid: false, reason: 'Body not raised' };
    }
    if (location && cycle?.dumpLocation) {
      const distance = calculateDistance(location, cycle.dumpLocation);
      if (distance > (cycle.dumpRadius || DUMP_RADIUS)) {
        return { valid: false, reason: 'Hauler not in dump radius' };
      }
    }
  }
  
  // DUMPING -> HAULING_EMPTY
  if (currentStatus === 'DUMPING' && targetStatus === 'HAULING_EMPTY') {
    if (hauler.bodyUp) {
      return { valid: false, reason: 'Body still raised' };
    }
  }
  
  return { valid: true };
}

/**
 * Check for automatic status transitions based on telemetry
 */
async function checkAutoTransitions(
  haulerId: string,
  hauler: Hauler,
  telemetry: any
): Promise<void> {
  
  if (!hauler.cycleId) return;
  
  const cycleDoc = await db.collection('cycles').doc(hauler.cycleId).get();
  const cycle = cycleDoc.data() as Cycle;
  
  if (!cycle || cycle.completed) return;
  
  let loader: Loader | null = null;
  if (cycle.loaderId) {
    const loaderDoc = await db.collection('loaders').doc(cycle.loaderId).get();
    loader = loaderDoc.data() as Loader || null;
  }
  
  const location: GeoLocation = {
    lat: telemetry.lat,
    lng: telemetry.lng,
    accuracy: telemetry.accuracy,
  };
  
  const currentStatus = hauler.currentStatus;
  let newStatus: string | null = null;
  let cause: string | null = null;
  
  // Auto T1: HAULING_EMPTY -> QUEUING (entering loader radius)
  if (currentStatus === 'HAULING_EMPTY' && loader) {
    const distance = calculateDistance(location, loader.location);
    if (distance <= (loader.radius || LOADER_RADIUS)) {
      newStatus = 'QUEUING';
      cause = 'ENTERED_LOADER_RADIUS';
    }
  }
  
  // Auto T2: Check if at dump point with body up
  if (currentStatus === 'HAULING_LOAD' && cycle.dumpLocation && telemetry.bodyUp) {
    const distance = calculateDistance(location, cycle.dumpLocation);
    if (distance <= (cycle.dumpRadius || DUMP_RADIUS)) {
      newStatus = 'DUMPING';
      cause = 'BODY_UP';
    }
  }
  
  // Apply automatic transition
  if (newStatus && cause) {
    const haulerRef = db.collection('haulers').doc(haulerId);
    const newSeq = hauler.eventSeq + 1;
    const now = admin.firestore.Timestamp.now();
    
    const eventId = `${haulerId}_${hauler.cycleId}_${newSeq}_${cause}`;
    
    await db.collection('hauler_events').doc(eventId).set({
      haulerId,
      cycleId: hauler.cycleId,
      fromStatus: currentStatus,
      toStatus: newStatus,
      cause,
      deviceTime: telemetry.deviceTime,
      serverTime: now,
      seq: newSeq,
      dedupKey: eventId,
      synced: true,
      auto: true,
    });
    
    await haulerRef.update({
      currentStatus: newStatus,
      lastStatusChangeAt: now,
      eventSeq: newSeq,
    });
    
    console.log(`Auto transition for ${haulerId}: ${currentStatus} -> ${newStatus}`);
  }
}

/**
 * Mark intent as processed
 */
async function markIntentProcessed(
  intentId: string,
  success: boolean,
  errorMessage?: string,
  resultEventId?: string
): Promise<void> {
  await db.collection('intents').doc(intentId).update({
    processed: true,
    success,
    errorMessage,
    resultEventId,
    processedAt: admin.firestore.Timestamp.now(),
  });
}

/**
 * Calculate haversine distance between two points (meters)
 */
function calculateDistance(from: GeoLocation, to: GeoLocation): number {
  const R = 6371000; // Earth radius in meters
  const lat1 = from.lat * Math.PI / 180;
  const lat2 = to.lat * Math.PI / 180;
  const dLat = (to.lat - from.lat) * Math.PI / 180;
  const dLng = (to.lng - from.lng) * Math.PI / 180;
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1) * Math.cos(lat2) *
            Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  
  return R * c;
}

/**
 * Periodic cleanup of old telemetry data
 */
export const cleanupTelemetry = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7); // Keep 7 days
    
    const batch = db.batch();
    const oldDocs = await db.collection('telemetry')
      .where('createdAt', '<', cutoff)
      .limit(500)
      .get();
    
    oldDocs.docs.forEach(doc => batch.delete(doc.ref));
    
    if (oldDocs.size > 0) {
      await batch.commit();
      console.log(`Deleted ${oldDocs.size} old telemetry records`);
    }
  });

/**
 * Health check endpoint
 */
export const healthCheck = functions.https.onRequest((req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'hauler-truck-functions',
  });
});

