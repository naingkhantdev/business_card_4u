import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/dataagent/bca_data_agent.dart';
import '../../data/vos/company_model.dart';
import '../../utils/app_result.dart';
import '../../utils/error_message.dart';
import '../data_agent_providers.dart';

class CompanyState {
  final List<CompanyModel> companies;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  // Pagination: which page the list currently ends on, whether the server
  // has more beyond it, and whether a "load more" fetch is in flight (kept
  // separate from `isLoading` so it doesn't blank the whole list with a
  // full-page spinner while the user is scrolling).
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  CompanyState({
    this.companies = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  CompanyState copyWith({
    List<CompanyModel>? companies,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CompanyState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

const _kCompanyPageSize = 20;

final companyProvider =
    AsyncNotifierProvider<CompanyNotifier, CompanyState>(CompanyNotifier.new);

class CompanyNotifier extends AsyncNotifier<CompanyState> {
  late final BcaDataAgent _dataAgent;

  @override
  Future<CompanyState> build() async {
    _dataAgent = ref.read(bcaDataAgentProvider);

    // Riverpod assigns this future's value to `state` wholesale when it
    // resolves, so `build` must not call the methods that write `state` —
    // a parallel write from a page would be overwritten by the stale value.
    return _loadCompanies();
  }

  Future<CompanyState> _loadCompanies() async {
    try {
      final page = await _dataAgent.getCompanies(
          page: 1, perPage: _kCompanyPageSize);
      return CompanyState(
        companies: page.companies,
        currentPage: 1,
        hasMore: page.hasMore,
      );
    } catch (e) {
      return CompanyState(
        companies: [],
        errorMessage: friendlyErrorMessage(e),
      );
    }
  }

  Future<CompanyState> fetchCompanies() async {
    state = const AsyncLoading();
    final newState = await _loadCompanies();
    state = AsyncData(newState);
    return newState;
  }

  /// Fetches the next page and appends it to the current list. Called as the
  /// user nears the bottom of the Manage Companies list; a no-op while
  /// already loading or once the server reports no more pages.
  Future<void> loadMoreCompanies() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    try {
      final page = await _dataAgent.getCompanies(
          page: nextPage, perPage: _kCompanyPageSize);
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(
        companies: [...latest.companies, ...page.companies],
        currentPage: nextPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(
        isLoadingMore: false,
        errorMessage: friendlyErrorMessage(e),
      ));
    }
  }

  Future<AppResult> createCompany(Map<String, dynamic> data) async {
    state = AsyncData(
        state.value?.copyWith(isSaving: true) ?? CompanyState(isSaving: true));
    try {
      final company = await _dataAgent.createCompany(data);
      if (company != null) {
        final updatedCompanies = [company, ...?state.value?.companies];
        state = AsyncData(state.value!.copyWith(
          companies: updatedCompanies,
          isSaving: false,
          errorMessage: null,
        ));
      } else {
        state = AsyncData(state.value?.copyWith(
              isSaving: false,
              errorMessage: null,
            ) ??
            CompanyState());
      }
      return const AppResult(true, 'Company created successfully');
    } catch (e) {
      state = AsyncData(state.value?.copyWith(
            isSaving: false,
            errorMessage: friendlyErrorMessage(e),
          ) ??
          CompanyState());
      return AppResult(false, friendlyErrorMessage(e));
    }
  }

  Future<AppResult> updateCompany(int id, Map<String, dynamic> data) async {
    state = AsyncData(
        state.value?.copyWith(isSaving: true) ?? CompanyState(isSaving: true));
    try {
      final updatedCompany = await _dataAgent.updateCompany(id, data);
      if (updatedCompany != null) {
        final updatedCompanies = state.value?.companies.map((c) {
          return c.id == id ? updatedCompany : c;
        }).toList();
        state = AsyncData(state.value!.copyWith(
          companies: updatedCompanies ?? [],
          isSaving: false,
          errorMessage: null,
        ));
      } else {
        state = AsyncData(state.value?.copyWith(
              isSaving: false,
              errorMessage: null,
            ) ??
            CompanyState());
      }
      return const AppResult(true, 'Company updated successfully');
    } catch (e) {
      state = AsyncData(state.value?.copyWith(
            isSaving: false,
            errorMessage: friendlyErrorMessage(e),
          ) ??
          CompanyState());
      return AppResult(false, friendlyErrorMessage(e));
    }
  }

  Future<AppResult> deleteCompany(int id) async {
    try {
      final message = await _dataAgent.deleteCompany(id);
      final updatedCompanies =
          state.value?.companies.where((c) => c.id != id).toList() ?? [];
      state = AsyncData(state.value!.copyWith(
        companies: updatedCompanies,
        errorMessage: null,
      ));
      return AppResult(true, message ?? 'Company deleted');
    } catch (e) {
      state = AsyncData(
          state.value?.copyWith(errorMessage: friendlyErrorMessage(e)) ?? CompanyState());
      return AppResult(false, friendlyErrorMessage(e));
    }
  }

  /// Finds the company a scanned card names, creating it when it is new.
  ///
  /// A scan rarely yields more than a name, so the created record carries only
  /// that — the API no longer demands industry or business type up front, and
  /// whoever owns the company can complete its profile later. An existing
  /// company is always reused rather than duplicated.
  ///
  /// Returns null when the name is blank or the create call fails, leaving the
  /// caller to fall back on the manual picker.
  Future<({CompanyModel company, bool created})?> resolveByName(
      String name) async {
    final match = await findByName(name);
    if (match != null) return (company: match, created: false);

    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final created = await createMinimal(trimmed);
    if (created == null) return null;
    return (company: created, created: true);
  }

  /// Looks for a company already on file whose name matches, without
  /// creating one when it isn't found. Pages through the whole list — not
  /// just what's currently loaded for the Manage Companies screen — so a
  /// match further down never gets missed.
  ///
  /// Returns null for a blank name or when nothing matches.
  Future<CompanyModel?> findByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    // The list loads on build, but a scan can finish before that does.
    var companies = state.value?.companies ?? const <CompanyModel>[];
    if (companies.isEmpty) {
      companies = (await fetchCompanies()).companies;
    }

    final key = _nameKey(trimmed);
    for (final company in companies) {
      if (_nameKey(company.name) == key) {
        return company;
      }
    }

    // The loaded companies are now just the first page or two, not
    // necessarily the whole list — check the rest of the pages before
    // concluding there is no match, or a caller would create a duplicate of
    // one that's simply further down the list.
    if (state.value?.hasMore ?? false) {
      final rest = await _fetchRemainingCompanies();
      for (final company in rest) {
        if (_nameKey(company.name) == key) {
          return company;
        }
      }
    }

    return null;
  }

  /// Creates a company carrying only a name — everything else on the profile
  /// can be filled in later from the Companies tab. Returns null on failure.
  Future<CompanyModel?> createMinimal(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    state = AsyncData(
        state.value?.copyWith(isSaving: true) ?? CompanyState(isSaving: true));
    try {
      final created = await _dataAgent.createCompany({'name': trimmed});
      if (created == null) {
        state =
            AsyncData(state.value?.copyWith(isSaving: false) ?? CompanyState());
        return null;
      }

      state = AsyncData(state.value!.copyWith(
        companies: [created, ...state.value!.companies],
        isSaving: false,
        errorMessage: null,
      ));
      return created;
    } catch (e) {
      state = AsyncData(state.value?.copyWith(
            isSaving: false,
            errorMessage: friendlyErrorMessage(e),
          ) ??
          CompanyState());
      return null;
    }
  }

  /// Pages through everything past what's already loaded, without touching
  /// `state` — used only for the duplicate check in [resolveByName], which
  /// must not clobber the list the Manage Companies page is scrolling.
  Future<List<CompanyModel>> _fetchRemainingCompanies() async {
    final all = <CompanyModel>[];
    var page = (state.value?.currentPage ?? 1) + 1;
    while (true) {
      final result = await _dataAgent.getCompanies(page: page, perPage: 100);
      all.addAll(result.companies);
      if (!result.hasMore) break;
      page++;
    }
    return all;
  }

  /// Collapses the differences OCR introduces — capitalisation that follows the
  /// card's typography, wrapped-line spacing, and the full stop card layouts
  /// like to end on — so "ACME  Co." matches "Acme Co". Deliberately does not
  /// strip punctuation wholesale: that would erase names written in scripts
  /// without Latin letters.
  static String _nameKey(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[.,]+$'), '')
      .trim();
}
