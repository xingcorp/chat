# Isar v4 (4.0.0-dev.14) Gotchas & Rules
# Applies to: flutter_chat_app/lib/**/*.dart (any code using Isar)

## ⚠️ CRITICAL: id=0 is a VALID ID, NOT auto-increment

In Isar v4 (4.0.0-dev.14), `id=0` is treated as a **valid, concrete ID** — NOT as an auto-increment sentinel.

**What this means:**
- `collection.put(objectWithId0)` will ALWAYS write to row id=0
- Calling `put()` multiple times with different objects that all have `id=0` will **overwrite the same single row**
- This is different from Isar v3 where `id = Isar.autoIncrement` (which was `null` or a special sentinel) triggered auto-increment

**Root cause:**
- `put()` delegates to `putAll()` → calls `serialize()` → returns `object.id` → passes to `isar_insert_save(ptr, id)`
- If `object.id == 0`, it passes `0` as the ID, which upserts at row 0

### MUST follow rule for new records

```dart
// ❌ WRONG — all new objects overwrite row 0
isar.write((isar) {
  isar.messageModels.put(newMessage); // newMessage.id == 0
});

// ❌ WRONG — same problem with putAll
isar.write((isar) {
  isar.messageModels.putAll(newMessages); // all have id == 0 → only 1 row saved
});

// ✅ CORRECT — explicitly assign auto-increment ID for new records
isar.write((isar) {
  final toSave = newMessage.id == 0
      ? newMessage.copyWith(id: isar.messageModels.autoIncrement())
      : newMessage;
  isar.messageModels.put(toSave);
});

// ✅ CORRECT — batch with auto-increment
isar.write((isar) {
  for (final msg in newMessages) {
    final toSave = msg.id == 0
        ? msg.copyWith(id: isar.messageModels.autoIncrement())
        : msg;
    isar.messageModels.put(toSave);
  }
});
```

### autoIncrement() behavior
- `collection.autoIncrement()` returns the next available ID
- After app restart, the counter resets to `max(existing IDs) + 1`
- If collection is empty, counter starts at `1`
- Safe to call multiple times in the same transaction — each call returns a new unique ID

## Upsert Pattern (when records may or may not exist)

For upsert operations, resolve existing records by unique fields (NOT by Isar int ID):

```dart
void saveMessageUpsert(MessageModel message) {
  isar.write((isar) {
    // 1. Try to find existing record by unique business key
    final existing = isar.messageModels.where()
        .serverIdEqualTo(message.serverId!).findFirst();

    final MessageModel toSave;
    if (existing != null) {
      // Update: reuse existing Isar ID
      toSave = message.copyWith(id: existing.id);
    } else {
      // Insert: get new auto-increment ID
      toSave = message.copyWith(id: isar.messageModels.autoIncrement());
    }
    isar.messageModels.put(toSave);
  });
}
```

## Applies to ALL collections

This `id=0` issue affects **every** Isar collection, not just messages:
- `ChatModel` — check `saveChat()`, `saveChatsBatch()`
- `MessageModel` — check `saveMessage()`, `saveMessageUpsert()`, `saveMessagesUpsert()`
- `UserModel` — check `saveUser()`
- `OfflineOperationModel`, `SyncMetadataModel`, `ChatDraftModel` — check all save methods

### Checklist when writing Isar save code
- [ ] Does the object potentially have `id == 0`?
- [ ] If yes, am I using `autoIncrement()` before `put()`?
- [ ] Am I checking for existing records by business key (serverId, localId) before deciding to insert vs update?
- [ ] Am I NOT relying on `putAll()` to auto-assign IDs?
