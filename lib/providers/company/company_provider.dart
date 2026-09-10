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

  CompanyState({
    this.companies = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  CompanyState copyWith({
    List<CompanyModel>? companies,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return CompanyState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

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
      final companies = await _dataAgent.getCompanies();
      return CompanyState(companies: companies ?? []);
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
        return (company: company, created: false);
      }
    }

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
      return (company: created, created: true);
    } catch (e) {
      state = AsyncData(state.value?.copyWith(
            isSaving: false,
            errorMessage: friendlyErrorMessage(e),
          ) ??
          CompanyState());
      return null;
    }
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
