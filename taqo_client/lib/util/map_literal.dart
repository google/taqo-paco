class MapLiteral<K, V> {
  final Map<K, V> _map;
  const MapLiteral(this._map);

  // The following code are supposed to forward methods/properties to [_map].
  // However, currently we only forward what will be used in our project
  Iterable<K> get keys => _map.keys;
  Iterable<V> get values => _map.values;
}
