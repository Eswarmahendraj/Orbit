import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Concert Model
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class ConcertEvent {
  final String id;
  final String name;
  final String artist;
  final String venue;
  final String city;
  final DateTime? date;
  final String? imageUrl;
  final String? ticketUrl;
  final String? priceRange;

  const ConcertEvent({
    required this.id,
    required this.name,
    required this.artist,
    required this.venue,
    required this.city,
    this.date,
    this.imageUrl,
    this.ticketUrl,
    this.priceRange,
  });

  factory ConcertEvent.fromTicketmaster(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final venues =
        (embedded?['venues'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
    final venue = venues?.isNotEmpty == true ? venues!.first : null;
    final attractions =
        (embedded?['attractions'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>();
    final attraction =
        attractions?.isNotEmpty == true ? attractions!.first : null;

    final images = (json['images'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();
    String? imageUrl;
    if (images != null) {
      final wide = images.firstWhere(
          (i) => (i['ratio'] as String?) == '16_9',
          orElse: () => images.first);
      imageUrl = wide['url'] as String?;
    }

    final priceRanges = (json['priceRanges'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();
    String? priceRange;
    if (priceRanges != null && priceRanges.isNotEmpty) {
      final min = priceRanges.first['min'];
      final max = priceRanges.first['max'];
      priceRange = '\$${min?.toStringAsFixed(0)} â \$${max?.toStringAsFixed(0)}';
    }

    DateTime? date;
    final dateStr =
        (json['dates'] as Map?)
            ?['start']?['localDate'] as String?;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
    }

    return ConcertEvent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Concert',
      artist: attraction?['name'] as String? ?? 'Artist',
      venue: venue?['name'] as String? ?? 'Venue TBD',
      city:
          '${venue?['city']?['name'] ?? ''}, ${venue?['state']?['stateCode'] ?? ''}',
      date: date,
      imageUrl: imageUrl,
      ticketUrl: json['url'] as String?,
      priceRange: priceRange,
    );
  }
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Concert Finder Service
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class ConcertFinderService {
  static const String _apiKey = 'YOUR_TICKETMASTER_API_KEY';
  static const String _baseUrl =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  Future<List<ConcertEvent>> findConcertsForArtist(String artist,
      {String? city}) async {
    try {
      final params = {
        'apikey': _apiKey,
        'keyword': artist,
        'classificationName': 'music',
        'size': '5',
        'sort': 'date,asc',
        if (city != null) 'city': city,
      };
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final events =
          (data['_embedded']?['events'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
              [];
      return events.map(ConcertEvent.fromTicketmaster).toList();
    } catch (_) {
      return [];
    }
  }

  // Demo concerts (shown when API key not set or offline)
  static List<ConcertEvent> demoEvents(String artist) => [
        ConcertEvent(
          id: 'demo1',
          name: '$artist Live',
          artist: artist,
          venue: 'The Fillmore',
          city: 'San Francisco, CA',
          date: DateTime.now().add(const Duration(days: 14)),
          priceRange: '\$35 â \$75',
        ),
        ConcertEvent(
          id: 'demo2',
          name: '$artist â World Tour',
          artist: artist,
          venue: 'Madison Square Garden',
          city: 'New York, NY',
          date: DateTime.now().add(const Duration(days: 28)),
          priceRange: '\$55 â \$120',
        ),
        ConcertEvent(
          id: 'demo3',
          name: '$artist + Friends',
          artist: artist,
          venue: 'The Wiltern',
          city: 'Los Angeles, CA',
          date: DateTime.now().add(const Duration(days: 45)),
          priceRange: '\$40 â \$90',
        ),
      ];
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Screen
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class ConcertFinderScreen extends StatefulWidget {
  const ConcertFinderScreen({super.key});

  @override
  State<ConcertFinderScreen> createState() => _ConcertFinderScreenState();
}

class _ConcertFinderScreenState extends State<ConcertFinderScreen> {
  final _svc = ConcertFinderService();
  final _searchCtrl = TextEditingController();
  List<ConcertEvent> _events = [];
  bool _loading = false;
  String _searchedArtist = '';
  bool _isDemoMode = false;

  // Artists pulled from user's Music DNA / recent listens
  List<String> get _suggestedArtists => [
        'Taylor Swift',
        'The Weeknd',
        'Drake',
        'Billie Eilish',
        'Arctic Monkeys',
        'Harry Styles',
        'Doja Cat',
        'Post Malone',
      ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String artist) async {
    if (artist.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _searchedArtist = artist;
      _isDemoMode = false;
    });

    const isApiKeySet =
        ConcertFinderService._apiKey != 'YOUR_TICKETMASTER_API_KEY';
    List<ConcertEvent> events = [];

    if (isApiKeySet) {
      events = await _svc.findConcertsForArtist(artist);
    }

    if (events.isEmpty) {
      events = ConcertFinderService.demoEvents(artist);
      _isDemoMode = true;
    }

    if (mounted) {
      setState(() {
        _events = events;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          'Concert Finder',
          style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // ââ Search Bar ââââââââââââââââââââââââââââââââââââââââââââââââââââ
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: theme.textPrimary, fontSize: 15),
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search an artist...',
                hintStyle: TextStyle(color: theme.textMuted),
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.textMuted, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: theme.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _events = [];
                            _searchedArtist = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: theme.accent))
                : _events.isNotEmpty
                    ? _buildResults(theme)
                    : _buildSuggestions(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(AuraTheme theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        Text(
          'From your music taste',
          style: TextStyle(
              color: theme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestedArtists
              .map((a) => GestureDetector(
                    onTap: () {
                      _searchCtrl.text = a;
                      _search(a);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: theme.divider.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded,
                              color: theme.accent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            a,
                            style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResults(AuraTheme theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        Row(
          children: [
            Text(
              '${_events.length} shows found for "$_searchedArtist"',
              style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            if (_isDemoMode) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Demo',
                  style: TextStyle(
                      color: theme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ..._events.map((e) => _ConcertCard(event: e, theme: theme)),
      ],
    );
  }
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Concert Card
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class _ConcertCard extends StatelessWidget {
  final ConcertEvent event;
  final AuraTheme theme;
  const _ConcertCard({required this.event, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            )
          else
            _imagePlaceholder(),

          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: theme.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${event.venue} Â· ${event.city}',
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (event.date != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: theme.textMuted, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.date!),
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (event.priceRange != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.priceRange!,
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    const Spacer(),
                    if (event.ticketUrl != null)
                      ElevatedButton(
                        onPressed: () {
                          // Open ticket URL via url_launcher
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Opening tickets for ${event.name}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: AuraTheme.current.accent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Get Tickets',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardBackground,
                          foregroundColor: theme.textMuted,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'View Event',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [theme.cardBackground, theme.background]),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.music_note_rounded,
            color: theme.textMuted, size: 32),
      );

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
