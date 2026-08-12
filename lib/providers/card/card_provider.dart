import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../network/dataagent/bca_data_agent.dart';
import '../../data/vos/address_model.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/request/create_card_request.dart';
import '../../utils/app_result.dart';
import '../data_agent_providers.dart';

// Combined Card State
class CardState {
  final List<BusinessCardModel> cards;
  final List<BusinessCardModel> friendRequests;
  final bool isLoading;
  final bool isCreating;
  final String? deleteMessage;

  CardState({
    this.cards = const [],
    this.friendRequests = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.deleteMessage,
  });

  CardState copyWith({
    List<BusinessCardModel>? cards,
    List<BusinessCardModel>? friendRequests,
    bool? isLoading,
    bool? isCreating,
    String? deleteMessage,
  }) {
    return CardState(
      cards: cards ?? this.cards,
      friendRequests: friendRequests ?? this.friendRequests,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      deleteMessage: deleteMessage ?? this.deleteMessage,
    );
  }
}

final cardProvider =
    AsyncNotifierProvider<CardNotifier, CardState>(CardNotifier.new);

class CardNotifier extends AsyncNotifier<CardState> {
  late final BcaDataAgent _dataAgent;

  @override
  Future<CardState> build() async {
    _dataAgent = ref.read(bcaDataAgentProvider);
    return fetchCards();
  }

  Future<CardState> fetchCards() async {
    state = const AsyncLoading();
    try {
      final res = await _dataAgent.getCards();
      final newState = CardState(
        cards: res?.cards ?? [],
        friendRequests: state.value?.friendRequests ?? [],
      );
      state = AsyncData(newState);
      return newState;
    } catch (e) {
      final newState = CardState(
        cards: state.value?.cards ?? [],
        friendRequests: state.value?.friendRequests ?? [],
      );
      state = AsyncData(newState);
      return newState;
    }
  }

  Future<AppResult> createCard({
    String? name,
    int? companyId,
    String? position,
    List<String>? phones,
    List<String>? emails,
    List<AddressModel>? addresses,
    String? bio,
    String? profileImage,
    XFile? imageFile,
    String? cardType,
  }) async {
    state = AsyncData(
        state.value?.copyWith(isCreating: true) ?? CardState(isCreating: true));
    try {
      final request = CreateCardRequest(
        name: name,
        companyId: companyId,
        position: position,
        phones: phones,
        emails: emails,
        addresses: addresses,
        bio: bio,
        profileImage: profileImage,
        cardType: cardType,
      );

      final createdCard =
          await _dataAgent.createCard(request.toJson(), imageFile: imageFile);

      if (createdCard != null) {
        final updatedCards = [createdCard, ...?state.value?.cards];
        state = AsyncData(state.value!.copyWith(
          cards: updatedCards,
          isCreating: false,
        ));
        return const AppResult(true, 'Card created successfully');
      } else {
        state =
            AsyncData(state.value?.copyWith(isCreating: false) ?? CardState());
        return const AppResult(false, 'Server did not return the created card');
      }
    } catch (e) {
      state =
          AsyncData(state.value?.copyWith(isCreating: false) ?? CardState());
      return AppResult(false, e.toString());
    }
  }

  Future<AppResult> updateCard(
    int id, {
    String? name,
    int? companyId,
    String? position,
    List<String>? phones,
    List<String>? emails,
    List<AddressModel>? addresses,
    String? bio,
    String? profileImage,
    XFile? imageFile,
  }) async {
    state = AsyncData(
        state.value?.copyWith(isCreating: true) ?? CardState(isCreating: true));
    try {
      final request = CreateCardRequest(
        name: name,
        companyId: companyId,
        position: position,
        phones: phones,
        emails: emails,
        addresses: addresses,
        bio: bio,
        profileImage: profileImage,
      );

      final updatedCard = await _dataAgent.updateCard(id, request.toJson(),
          imageFile: imageFile);

      if (updatedCard != null) {
        final updatedCards = state.value?.cards.map((card) {
          return card.id == id ? updatedCard : card;
        }).toList();

        state = AsyncData(state.value!.copyWith(
          cards: updatedCards ?? [],
          isCreating: false,
        ));
      } else {
        state =
            AsyncData(state.value?.copyWith(isCreating: false) ?? CardState());
      }

      return const AppResult(true, 'Card updated successfully');
    } catch (e) {
      state =
          AsyncData(state.value?.copyWith(isCreating: false) ?? CardState());
      return AppResult(false, e.toString());
    }
  }

  Future<AppResult> deleteCard(int id) async {
    try {
      final message = await _dataAgent.deleteCard(id);
      final updatedCards =
          state.value?.cards.where((card) => card.id != id).toList() ?? [];
      state = AsyncData(state.value!.copyWith(
        cards: updatedCards,
        deleteMessage: message,
      ));
      return AppResult(true, message ?? 'Card deleted');
    } catch (e) {
      state = AsyncData(
          state.value?.copyWith(deleteMessage: 'Failed to delete card') ??
              CardState());
      return AppResult(false, e.toString());
    }
  }

  Future<List<BusinessCardModel>> searchCards(
    String query, {
    int? companyId,
    String cardType = 'user_card',
    String? city,
    String? state,
    String? country,
  }) async {
    try {
      final res = await _dataAgent.searchCards(
        query,
        companyId: companyId,
        cardType: cardType,
        city: city,
        state: state,
        country: country,
      );
      return res ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<BusinessCardModel?> scanQr(String qrData) async {
    try {
      return await _dataAgent.scanQr(qrData);
    } catch (e) {
      return null;
    }
  }

  Future<AppResult> addFriend(int cardId) async {
    try {
      await _dataAgent.addFriend(cardId);
      await fetchFriendRequests();
      return const AppResult(true, 'Friend request sent');
    } catch (e) {
      return AppResult(false, e.toString());
    }
  }

  Future<void> fetchFriendRequests() async {
    try {
      final requests = await _dataAgent.getFriendRequests();
      state = AsyncData(state.value?.copyWith(friendRequests: requests ?? []) ??
          CardState(friendRequests: []));
    } catch (e) {
      state =
          AsyncData(state.value?.copyWith(friendRequests: []) ?? CardState());
    }
  }

  Future<AppResult> acceptFriendRequest(int cardId) async {
    try {
      await _dataAgent.acceptFriendRequest(cardId);
      final updatedRequests = state.value?.friendRequests
              .where((card) => card.id != cardId)
              .toList() ??
          [];
      state = AsyncData(state.value!.copyWith(friendRequests: updatedRequests));
      await fetchCards();
      return const AppResult(true, 'Friend request accepted');
    } catch (e) {
      return AppResult(false, e.toString());
    }
  }

  Future<AppResult> rejectFriendRequest(int cardId) async {
    try {
      await _dataAgent.rejectFriendRequest(cardId);
      final updatedRequests = state.value?.friendRequests
              .where((card) => card.id != cardId)
              .toList() ??
          [];
      state = AsyncData(state.value!.copyWith(friendRequests: updatedRequests));
      return const AppResult(true, 'Friend request rejected');
    } catch (e) {
      return AppResult(false, e.toString());
    }
  }

  Future<AppResult> removeFriend(int cardId) async {
    try {
      await _dataAgent.removeFriend(cardId);
      await fetchCards();
      await fetchFriendRequests();
      return const AppResult(true, 'Friend removed');
    } catch (e) {
      return AppResult(false, e.toString());
    }
  }
}
