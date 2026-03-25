/**
 * Scheduled retention for `audit_logs`: deletes entries older than RETENTION_DAYS.
 * Uses Admin SDK (bypasses Firestore security rules). Deploy: firebase deploy --only functions
 *
 * Keep RETENTION_DAYS in sync with AuditLogService.retentionDays in the Flutter app.
 */
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');

initializeApp();

const COLLECTION = 'audit_logs';
const RETENTION_DAYS = 90;
const BATCH_SIZE = 500;

exports.purgeAuditLogs = onSchedule(
  {
    schedule: 'every day 03:00',
    timeZone: 'Etc/UTC',
    retryCount: 2,
  },
  async () => {
    const db = getFirestore();
    const cutoffMs = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;
    const cutoffTs = Timestamp.fromMillis(cutoffMs);
    let totalDeleted = 0;

    for (;;) {
      const snap = await db
        .collection(COLLECTION)
        .where('createdAt', '<', cutoffTs)
        .limit(BATCH_SIZE)
        .get();

      if (snap.empty) break;

      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      totalDeleted += snap.size;
      if (snap.size < BATCH_SIZE) break;
    }

    console.log(
      `purgeAuditLogs: deleted ${totalDeleted} audit doc(s) with createdAt before ${cutoffTs.toDate().toISOString()}`,
    );
  },
);
