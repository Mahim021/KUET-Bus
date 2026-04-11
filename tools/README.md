Quick Seeder — tools/README

1) Copy your service account JSON into the project root and name it `serviceAccountKey.json` (or keep original name and set `GOOGLE_APPLICATION_CREDENTIALS` accordingly).

2) Install Node dependencies (one-time):

```powershell
cd F:\system\KUET-Bus
npm install
```

3) Set the env var and attach admin claim to your admin user (replace path/email as needed):

PowerShell:
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="F:\system\KUET-Bus\serviceAccountKey.json"
npm run set-admin -- admin@kuet.ac.bd
```

macOS / Linux:
```bash
export GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
npm run set-admin -- admin@kuet.ac.bd
```

4) Run the seeder (writes sample `notices`, `buses`, `routes`, `schedules`, `bus_locations`):

PowerShell:
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="F:\system\KUET-Bus\serviceAccountKey.json"
npm run seed
```

5) Verify data in Firebase Console → Firestore.

Notes:
- The Admin SDK bypasses Firestore rules — used only for seeding and admin tasks.
- Do NOT commit your service account JSON to source control.
