/// A memo with a fixed capacity: the least-recently-used entry is evicted once
/// [capacity] entries are held.
///
/// The theme and colour-scheme caches used to be documented as "bounded by
/// construction" — the key space was the fixed palette list, so they could
/// never grow. That stopped being true the moment a *free-form* seed became a
/// legal key: dragging the custom-colour picker produces one distinct seed per
/// pointer move, and every one of them kept a full `ColorScheme` and
/// `ThemeData` alive for the life of the process.
///
/// A plain unbounded `Map` cannot express "recently used matters", so this is
/// the smallest thing that does: on a hit the entry is re-inserted, which
/// pushes it to the back of the eviction queue, and the front falls off once
/// the cap is passed. The working set (nine palettes × two brightnesses × the
/// AMOLED variants) is far below any sane capacity, so eviction only ever
/// touches entries that are no longer being looked at.
class BoundedMemo<K, V extends Object> {
  BoundedMemo(this.capacity) : assert(capacity > 0);

  /// Maximum number of entries kept. Beyond this the least-recently-used entry
  /// is dropped; it is rebuilt on the next request.
  final int capacity;

  /// Insertion-ordered, so the *first* key is the least recently used one.
  final Map<K, V> _entries = <K, V>{};

  /// How many entries are held right now. Exposed so a test can assert that
  /// the cap is actually enforced rather than trusting the implementation.
  int get length => _entries.length;

  /// Drops [key] so the next request rebuilds it.
  ///
  /// Useful for values that are only conditionally cacheable: an asynchronous
  /// lookup that resolves to "not found" should not keep that answer for the
  /// life of the process, because the thing it looked for may appear later.
  void remove(K key) => _entries.remove(key);

  /// The cached [value] for [key], built with [build] on the first request (and
  /// again after an eviction).
  V getOrPut(K key, V Function() build) {
    // `remove` (rather than a lookup) is what re-orders the map: the entry
    // comes off the front of the insertion order and is put straight back at
    // the back, which marks it as the most recently used one. A hit that only
    // *read* the map would leave the entry where it was — the least recently
    // used entry would then be evicted even though it had just been asked
    // for, and the next request would rebuild it from scratch.
    final hit = _entries.remove(key);
    if (hit != null) {
      _entries[key] = hit;
      return hit;
    }

    final value = build();
    _entries[key] = value;
    while (_entries.length > capacity && _entries.isNotEmpty) {
      _entries.remove(_entries.keys.first);
    }
    return value;
  }
}
