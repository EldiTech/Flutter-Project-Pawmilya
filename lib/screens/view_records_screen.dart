import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class ViewRecordsScreen extends StatefulWidget {
  const ViewRecordsScreen({super.key});

  @override
  State<ViewRecordsScreen> createState() => _ViewRecordsScreenState();
}

class _ViewRecordsScreenState extends State<ViewRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      appBar: AppBar(
        title: Text(
          'View Records',
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final query = _searchController.text.trim().toLowerCase();
          final records = provider.pets.where((pet) {
            if (query.isEmpty) return true;
            return pet.name.toLowerCase().contains(query) ||
                pet.species.toLowerCase().contains(query) ||
                pet.breed.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textMid.withOpacity(0.9),
                    ),
                    hintText: 'Search records',
                    hintStyle: GoogleFonts.quicksand(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withOpacity(0.7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.warmAccent.withOpacity(0.7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          'No records found.',
                          style: GoogleFonts.quicksand(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.warmAccent.withOpacity(0.58)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textDark.withOpacity(0.07),
                                  blurRadius: 18,
                                  offset: const Offset(0, 9),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _RecordThumbnail(name: item.name),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textDark,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${item.species} • ${item.breed} • ${item.age}',
                                        style: GoogleFonts.quicksand(
                                          color: AppColors.textMuted,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _StatusBadge(status: item.status),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordThumbnail extends StatelessWidget {
  const _RecordThumbnail({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warmAccent.withOpacity(0.9), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.warmAccent.withOpacity(0.45),
        child: Text(
          initial,
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.adoptionGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.adoptionGreen.withOpacity(0.35)),
      ),
      child: Text(
        status,
        style: GoogleFonts.quicksand(
          color: AppColors.adoptionGreen.withOpacity(0.95),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
