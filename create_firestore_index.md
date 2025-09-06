# Firestore Index Creation

## Required Index for Residents Collection

The app requires a composite index for the `residents` collection to support the query used in the residents page.

### Index Details:
- Collection: `residents`
- Fields:
  1. `buildingId` (Ascending)
  2. `lastName` (Ascending) 
  3. `firstName` (Ascending)

### Steps to Create:

1. Go to the Firebase Console: https://console.firebase.google.com/project/vaadly-project
2. Navigate to Firestore Database → Indexes
3. Click "Create Index"
4. Set Collection ID: `residents`
5. Add the following fields in order:
   - `buildingId` - Ascending
   - `lastName` - Ascending
   - `firstName` - Ascending
6. Click "Create"

### Alternative: Auto-create via Error Link
The console error provided this direct link:
https://console.firebase.google.com/v1/r/project/vaadly-project/firestore/indexes?create_composite=ClBwcm9qZWN0cy92YWFkbHktcHJvamVjdC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvcmVzaWRlbnRzL2luZGV4ZXMvXxABGg4KCmJ1aWxkaW5nSWQQARoMCghsYXN0TmFtZRABGg0KCWZpcnN0TmFtZRABGgwKCF9fbmFtZV9fEAE

This will automatically create the required index.

### Note:
Index creation can take several minutes to complete. The app will work properly once the index is created.
