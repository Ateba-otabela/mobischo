import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/parent/institution_details_screen.dart';
import 'package:mobischo/components/screens/parent/institution_image.dart';
import 'package:mobischo/models/institution.dart';
import 'package:mobischo/services/institution_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class SchoolAdvertScreen extends StatefulWidget {
  final String userCode;

  const SchoolAdvertScreen({Key? key, required this.userCode})
      : super(key: key);

  @override
  State<SchoolAdvertScreen> createState() => _SchoolAdvertScreenState();
}

class _SchoolAdvertScreenState extends State<SchoolAdvertScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = const [
    'Tout',
    'Universitaires',
    'Formations'
  ];
  final List<String> _typeFilters = const ['Tout', 'public', 'private'];
  Timer? _searchDebounce;

  List<Institution> _institutions = const [];
  bool _loading = true;
  bool _error = false;
  String _selectedCategory = 'Tout';
  String _selectedType = 'Tout';
  bool _showAllOthers = false;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final institutions = await InstitutionServices.getInstitutions(
        search: _searchController.text,
        category: _selectedCategory == 'Tout'
            ? null
            : _selectedCategory == 'Formations'
                ? 'secondaire'
                : 'universitaire',
        type: _selectedType == 'Tout' ? null : _selectedType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _institutions = institutions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _loadInstitutions();
      }
    });
  }

  List<Institution> get _featuredInstitutions =>
      _institutions.where((institution) => institution.featured).toList();

  List<Institution> get _otherInstitutions =>
      _institutions.where((institution) => !institution.featured).toList();

  Widget _categoryChip(String label) {
    final selected = label == _selectedCategory;
    final displayLabel = label == 'Tout'
        ? uiText(context, 'all')
        : label == 'Universitaires'
            ? uiText(context, 'universityCategoryPlural')
            : uiText(context, 'programs');
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(displayLabel),
        selected: selected,
        selectedColor: CustomTheme.blue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: Color(0xffe5e7eb), width: 1),
        onSelected: (_) {
          setState(() {
            _selectedCategory = label;
          });
          _loadInstitutions();
        },
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uiText(context, 'institutionType'),
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ..._typeFilters.map((type) {
                  final isSelected = type == _selectedType;
                  return ListTile(
                    title: Text(type == 'Tout'
                        ? uiText(context, 'all')
                        : type == 'public'
                            ? uiText(context, 'publicInstitution')
                            : uiText(context, 'privateInstitution')),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: CustomTheme.blue)
                        : null,
                    onTap: () => Navigator.of(context).pop(type),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedType != null) {
      setState(() {
        _selectedType = selectedType;
      });
      _loadInstitutions();
    }
  }

  void _openInstitutionDetails(Institution institution) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstitutionDetailsScreen(institution: institution),
      ),
    );
  }

  Widget _featuredCard(Institution institution) {
    return SizedBox(
      width: 260,
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openInstitutionDetails(institution),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: InstitutionImage(
                  imageAsset: institution.imageAsset,
                  imageUrl: institution.imageUrl,
                  logoUrl: institution.logoUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: InstitutionImage(
                        imageUrl: institution.logoUrl,
                        logoUrl: institution.imageUrl,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            institution.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  institution.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _institutionListCard(Institution institution) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openInstitutionDetails(institution),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InstitutionImage(
                  imageAsset: institution.imageAsset,
                  imageUrl: institution.imageUrl,
                  logoUrl: institution.logoUrl,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: InstitutionImage(
                            imageUrl: institution.logoUrl,
                            logoUrl: institution.imageUrl,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            iconSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            institution.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xffebfbee),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            institution.type == 'private'
                                ? uiText(context, 'privateInstitution')
                                : uiText(context, 'publicInstitution'),
                            style: const TextStyle(
                                color: Color(0xff1d7a48),
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          institution.category.toLowerCase() == 'secondaire' ||
                                  institution.category.toLowerCase() ==
                                      'secondaires'
                              ? uiText(context, 'programs')
                              : uiText(context, 'universityCategory'),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            institution.location,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: institution.programs.take(2).map((program) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xfff3f4f6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            program,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xff374151)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: institution.languages.take(2).map((language) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xffeff6ff),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            language,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xff1d4ed8)),
                          ),
                        );
                      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final featuredInstitutions = _featuredInstitutions;
    final otherInstitutions = _otherInstitutions;
    final visibleOthers =
        _showAllOthers ? otherInstitutions : otherInstitutions.take(4).toList();

    return SafeArea(
      child: Container(
        color: const Color(0xfff7faf7),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: uiText(context, 'searchInstitutions'),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => _scheduleSearch(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: CustomTheme.blue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1a3E9760),
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _openFilterSheet,
                      icon: const Icon(Icons.filter_list_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _error
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 40, color: CustomTheme.blue),
                                const SizedBox(height: 12),
                                Text(uiText(context, 'institutionsLoadError')),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _loadInstitutions,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(uiText(context, 'retry')),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CustomScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 52,
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  scrollDirection: Axis.horizontal,
                                  children:
                                      _categories.map(_categoryChip).toList(),
                                ),
                              ),
                            ),
                            if (featuredInstitutions.isEmpty &&
                                otherInstitutions.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xffe5e7eb)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            size: 42, color: CustomTheme.blue),
                                        SizedBox(height: 12),
                                        Text(
                                          uiText(context, 'noInstitutionFound'),
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (featuredInstitutions.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  child: Text(
                                    uiText(context, 'featuredInstitutions'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 248,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: featuredInstitutions.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) =>
                                        _featuredCard(
                                            featuredInstitutions[index]),
                                  ),
                                ),
                              ),
                            ],
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Autres Institutions',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87),
                                    ),
                                    if (otherInstitutions.length > 4)
                                      TextButton(
                                        onPressed: () => setState(() =>
                                            _showAllOthers = !_showAllOthers),
                                        child: Text(
                                          _showAllOthers
                                              ? 'Voir moins'
                                              : 'Voir plus',
                                          style: const TextStyle(
                                              color: CustomTheme.blue,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index.isOdd) {
                                      return const SizedBox(height: 12);
                                    }
                                    return _institutionListCard(
                                        visibleOthers[index ~/ 2]);
                                  },
                                  childCount: visibleOthers.isEmpty
                                      ? 0
                                      : visibleOthers.length * 2 - 1,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
