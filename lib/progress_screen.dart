import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assisted_learning/models/card_progress.dart';
import 'package:assisted_learning/services/progress_service.dart';
import 'package:assisted_learning/services/tts_service.dart';
import 'package:assisted_learning/sets_screen.dart';

class ProgressScreen extends StatefulWidget {
  final StudySet set;
  const ProgressScreen({super.key, required this.set});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<CardProgress> _progress = [];
  bool _isLoading = true;
  int _masteryPercent = 0;
  String? _filter; // null = show all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await ProgressService.loadSet(widget.set);
    final mastery = await ProgressService.setMasteryPercent(widget.set);
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _masteryPercent = mastery;
      _isLoading = false;
    });
  }

  List<CardProgress> get _filtered => _filter == null
      ? _progress
      : _progress.where((p) => p.masteryLabel == _filter).toList();

  int _count(String label) =>
      _progress.where((p) => p.masteryLabel == label).length;

  Future<void> _readSummaryAloud() async {
    final mastered = _count('Mastered');
    final familiar = _count('Familiar');
    final needsWork = _count('Needs work');
    final notStudied = _count('Not studied');
    final total = _progress.length;

    await TTSSettings.tts.speak(
      'Progress for ${widget.set.name}. '
      '$_masteryPercent percent mastered. '
      'Out of $total cards: '
      '$mastered mastered, '
      '$familiar familiar, '
      '$needsWork need work, '
      'and $notStudied not yet studied.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF364B9A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF364B9A),
        foregroundColor: Colors.white,
        title: Text(widget.set.name, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          Semantics(
            button: true,
            label: 'Read progress summary aloud',
            child: IconButton(
              icon: const Icon(Icons.volume_up_outlined),
              tooltip: 'Read aloud',
              onPressed: _readSummaryAloud,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFDB366)),
            )
          : Column(
              children: [
                _buildSummaryHeader(),
                const SizedBox(height: 8),
                _buildFilterChips(),
                const SizedBox(height: 8),
                Expanded(child: _buildCardList()),
              ],
            ),
    );
  }

  // ─── Summary header ───────────────────────────────────────────────────────

  Widget _buildSummaryHeader() {
    return Semantics(
      label: '$_masteryPercent percent of ${widget.set.name} mastered',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Mastery ring
            ExcludeSemantics(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: _masteryPercent / 100,
                      strokeWidth: 9,
                      backgroundColor: Colors.grey.shade200,
                      color: _masteryColor(_masteryPercent),
                    ),
                  ),
                  Text(
                    '$_masteryPercent%',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF364B9A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Text(
                'Mastered',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Three bucket row
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bucket('⭐', 'Mastered', _count('Mastered'), Colors.amber),
                  _divider(),
                  _bucket('✅', 'Familiar', _count('Familiar'), Colors.green),
                  _divider(),
                  _bucket('🔁', 'Needs work', _count('Needs work'), Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(height: 36, width: 1, color: Colors.grey.shade200);

  Widget _bucket(String emoji, String label, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Color _masteryColor(int percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return const Color(0xFFFDB366);
    return Colors.red;
  }

  // ─── Filter chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    // Three tiers + all + not studied
    const filters = <String?>[
      null,
      'Needs work',
      'Familiar',
      'Mastered',
      'Not studied',
    ];
    const labels = [
      'All',
      '🔁 Needs work',
      '✅ Familiar',
      '⭐ Mastered',
      '⬜ Not studied',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _filter == filters[i];
          return Semantics(
            button: true,
            selected: selected,
            label: 'Filter by ${labels[i]}',
            child: FilterChip(
              label: Text(
                labels[i],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: selected ? const Color(0xFF364B9A) : Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filter = filters[i]),
              selectedColor: const Color(0xFFFDB366),
              backgroundColor: Colors.white12,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  // ─── Card list ────────────────────────────────────────────────────────────

  Widget _buildCardList() {
    final cards = _filtered;
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No cards in this category.',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: cards.length,
      itemBuilder: (_, i) => _cardTile(cards[i]),
    );
  }

  Widget _cardTile(CardProgress p) {
    final pct = (p.accuracy * 100).round();
    return Semantics(
      label:
          '${p.question}: ${p.masteryLabel}. '
          '$pct percent accuracy. '
          '${p.correctCount} correct, ${p.wrongCount} wrong.',
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Text(
                  p.masteryEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        p.question,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF364B9A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ExcludeSemantics(
                      child: Text(
                        p.answer,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.accuracy,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          color: _accuracyColor(p.accuracy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _accuracyColor(p.accuracy),
                      ),
                    ),
                    Text(
                      '${p.correctCount}✓ ${p.wrongCount}✗',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    if (p.lastStudied != null)
                      Text(
                        _formatDate(p.lastStudied!),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 0.9) return Colors.green;
    if (accuracy >= 0.7) return const Color(0xFFFDB366);
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
