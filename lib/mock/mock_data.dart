class MockData {
  static final List<Map<String, dynamic>> devices = [
    {
      'id': '1',
      'name': 'Living Room TV',
      'type': 'tv',
      'isConnected': true,
      'ip': '192.168.1.10',
    },
    {
      'id': '2',
      'name': 'Bedroom Apple TV',
      'type': 'apple_tv',
      'isConnected': false,
      'ip': '192.168.1.12',
    },
    {
      'id': '3',
      'name': 'Kitchen Speaker',
      'type': 'speaker',
      'isConnected': false,
      'ip': '192.168.1.15',
    },
  ];

  static final List<Map<String, dynamic>> mediaItems = [
    {
      'id': '101',
      'title': 'Nature Documentary',
      'subtitle': '4K UHD • 1h 45m',
      'imageUrl': 'https://picsum.photos/seed/nature/400/225',
      'duration': 6300,
      'type': 'video',
    },
    {
      'id': '102',
      'title': 'Chill Beats',
      'subtitle': 'Lofi Radio • Live',
      'imageUrl': 'https://picsum.photos/seed/music/400/225',
      'duration': 0,
      'type': 'audio',
    },
    {
      'id': '103',
      'title': 'Family Vacation 2023',
      'subtitle': 'Photos • 142 items',
      'imageUrl': 'https://picsum.photos/seed/vacation/400/225',
      'duration': 0,
      'type': 'photo',
    },
  ];
}
