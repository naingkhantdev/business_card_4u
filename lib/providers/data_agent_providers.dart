import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dataagent/bca_data_agent.dart';
import '../network/dataagent/bca_data_agent_impl.dart';

// Bca Data Agent Provider
final bcaDataAgentProvider = Provider<BcaDataAgent>((ref) {
  return BcaDataAgentImpl();
});
