import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_agent_providers.dart';

/// Shown until the server answers, and if it can't — so the picker never
/// opens empty. Mirrors App\Support\Professions::DEFAULTS.
const kDefaultProfessions = [
  'Engineer',
  'Doctor',
  'Sailor',
  'Nurse',
  'Teacher',
  'Lawyer',
  'Accountant',
  'Designer',
  'Manager',
  'Sales',
];

/// Every profession anyone has saved, most used first, then unused defaults.
/// Invalidate after saving a card with a new profession to pick it up.
final professionsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final list = await ref.read(bcaDataAgentProvider).getProfessions();
    return list.isEmpty ? kDefaultProfessions : list;
  } catch (_) {
    return kDefaultProfessions;
  }
});
