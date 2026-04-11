const admin = require('firebase-admin');

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('ERROR: set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();

  try {
    console.log('Seeding Firestore...');

    // Notices
    const notices = [
      { id: 'welcome', title: 'Welcome', body: 'KUET Bus app seeded data', tag: 'INFO' },
      { id: 'schedule', title: 'Schedule Updated', body: 'New schedule added for semester', tag: 'EVENT' },
    ];
    for (const n of notices) {
      await db.collection('notices').doc(n.id).set({
        title: n.title,
        body: n.body,
        tag: n.tag,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    // Buses
    const buses = [
      { id: 'bus1', name: 'KUET Bus 1', number: 'KUET-01' },
      { id: 'bus2', name: 'KUET Bus 2', number: 'KUET-02' },
    ];
    for (const b of buses) {
      await db.collection('buses').doc(b.id).set({ name: b.name, number: b.number });
    }

    // Routes
    const routes = [
      { id: 'route1', name: 'Main Campus Loop', points: [] },
    ];
    for (const r of routes) {
      await db.collection('routes').doc(r.id).set({ name: r.name, points: r.points });
    }

    // Schedules
    const schedules = [
      {
        id: 'sched1',
        busId: 'bus1',
        routeId: 'route1',
        time: '08:00',
        period: 'AM',
        daysOfWeek: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        isActive: true,
      },
    ];
    for (const s of schedules) {
      await db.collection('schedules').doc(s.id).set(s, { merge: true });
    }

    // Bus locations (realtime-ish collection)
    await db.collection('bus_locations').doc('bus1').set({
      busId: 'bus1',
      lat: 23.8065,
      lng: 90.3535,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Seeding complete.');
    process.exit(0);
  } catch (err) {
    console.error('Seeding failed:', err);
    process.exit(1);
  }
}

main();
