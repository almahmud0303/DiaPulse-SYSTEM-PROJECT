/**
 * Scheduled retention for `audit_logs`: deletes entries older than RETENTION_DAYS.
 * Uses Admin SDK (bypasses Firestore security rules). Deploy: firebase deploy --only functions
 *
 * Keep RETENTION_DAYS in sync with AuditLogService.retentionDays in the Flutter app.
 */
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onRequest} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const crypto = require('crypto');

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

function hashSecondPassword(secondPassword, uid) {
  return crypto.createHash('sha256').update(`${secondPassword}${uid}`).digest('hex');
}

async function getOrCreateUser(auth, email, password) {
  try {
    return await auth.getUserByEmail(email);
  } catch (_) {
    return await auth.createUser({
      email,
      password,
      emailVerified: true,
      disabled: false,
    });
  }
}

exports.seedTestUsers = onRequest(async (req, res) => {
  if (process.env.FUNCTIONS_EMULATOR !== 'true') {
    res.status(403).json({
      ok: false,
      message: 'Seeding is allowed only in Firebase Emulator.',
    });
    return;
  }

  const db = getFirestore();
  const auth = getAuth();
  const defaultPassword = 'password';
  const doctorSecondPassword = 'lazy_0303';

  let patientsCreated = 0;
  let doctorsCreated = 0;
  let patientsUpdated = 0;
  let doctorsUpdated = 0;

  try {
    for (let i = 1; i <= 100; i++) {
      const email = `patient${String(i).padStart(3, '0')}@seed.local`;
      const user = await getOrCreateUser(auth, email, defaultPassword);

      const profile = {
        email,
        displayName: `Seed Patient ${i}`,
        role: 'patient',
        phone: '',
        blocked: false,
        professionalInvitePending: false,
        updatedAt: Timestamp.now(),
      };
      const ref = db.collection('users').doc(user.uid);
      const existing = await ref.get();
      if (existing.exists) {
        await ref.set(profile, {merge: true});
        patientsUpdated++;
      } else {
        await ref.set({...profile, createdAt: Timestamp.now()});
        patientsCreated++;
      }
    }

    for (let i = 1; i <= 10; i++) {
      const email = `doctor${String(i).padStart(3, '0')}@seed.local`;
      const user = await getOrCreateUser(auth, email, defaultPassword);
      const secondPasswordHash = hashSecondPassword(doctorSecondPassword, user.uid);

      const profile = {
        email,
        displayName: `Seed Doctor ${i}`,
        role: 'doctor',
        phone: '',
        blocked: false,
        professionalInvitePending: false,
        secondPasswordHash,
        updatedAt: Timestamp.now(),
      };
      const ref = db.collection('users').doc(user.uid);
      const existing = await ref.get();
      if (existing.exists) {
        await ref.set(profile, {merge: true});
        doctorsUpdated++;
      } else {
        await ref.set({...profile, createdAt: Timestamp.now()});
        doctorsCreated++;
      }
    }

    res.status(200).json({
      ok: true,
      emulatorOnly: true,
      credentials: {
        password: defaultPassword,
        doctorSecondPassword,
      },
      summary: {
        patientsCreated,
        patientsUpdated,
        doctorsCreated,
        doctorsUpdated,
      },
    });
  } catch (error) {
    console.error('seedTestUsers failed', error);
    res.status(500).json({
      ok: false,
      message: error instanceof Error ? error.message : String(error),
    });
  }
});
