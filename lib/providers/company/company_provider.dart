import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/dataagent/bca_data_agent.dart';
import '../../data/vos/company_model.dart';
import '../../utils/app_result.dart';
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
    return fetchCompanies();
  }

  Future<CompanyState> fetchCompanies() async {
    state = const AsyncLoading();
    try {
      final companies = await _dataAgent.getCompanies();
      final newState = CompanyState(companies: companies ?? []);
      state = AsyncData(newState);
      return newState;
    } catch (e) {
      final newState = CompanyState(
        companies: [],
        errorMessage: e.toString(),
      );
      state = AsyncData(newState);
      return newState;
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
      return AppResult(true, 'Company created successfully');
    } catch (e) {
      state = AsyncData(state.value?.copyWith(
            isSaving: false,
            errorMessage: e.toString(),
          ) ??
          CompanyState());
      return AppResult(false, e.toString());
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
      return AppResult(true, 'Company updated successfully');
    } catch (e) {
      state = AsyncData(state.value?.copyWith(
            isSaving: false,
            errorMessage: e.toString(),
          ) ??
          CompanyState());
      return AppResult(false, e.toString());
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
          state.value?.copyWith(errorMessage: e.toString()) ?? CompanyState());
      return AppResult(false, e.toString());
    }
  }
}
