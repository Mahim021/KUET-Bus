const admin = require('firebase-admin');

async function main() {
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const adminEmail = process.argv[2] || process.env.ADMIN_EMAIL;

  if (!keyPath) {
    console.error('ERROR: set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path');
    process.exit(1);
  }
  if (!adminEmail) {
    console.error('Usage: node set_admin_claim.js <admin-email>');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  try {
    const user = await admin.auth().getUserByEmail(adminEmail);

    // 1) Set custom claim so the Flutter app can detect the admin role
    await admin.auth().setCustomUserClaims(user.uid, { role: 'admin' });
    console.log(`✓ Set role:admin claim for ${adminEmail} (uid=${user.uid})`);

    // 2) Create / update the Firestore student document for this admin user
    const db = admin.firestore();
    const now = new Date().toISOString();
    const userRef = db.collection('users').doc(user.uid);

    await userRef.set(
      {
        uid: user.uid,
        name: user.displayName || 'Admin',
        email: user.email,
        kuetId: '',
        department: 'Admin',
        batch: '',
        role: 'admin',
        createdAt: now,
        updatedAt: now,
      },
      { merge: true }   // won't overwrite existing fields if doc already exists
    );
    console.log(`✓ Firestore users/${user.uid} created / updated`);

    process.exit(0);
  } catch (err) {
    console.error('Failed:', err);
    process.exit(1);
  }
}

main();
