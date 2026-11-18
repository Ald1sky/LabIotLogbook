import 'package:flutter_dotenv/flutter_dotenv.dart';

class BlockchainConfig {
  static const String contractAddress =
      '0x434bb4B9e10Dd9A277824f6E568FE389292a3f31';

  static const int chainId = 11155111;
  static const String networkName = 'Ethereum Sepolia';

  static String get rpcUrl =>
      dotenv.env['SEPOLIA_RPC_URL']?.trim() ?? '';

  static const String reownProjectId =
      '50a6f8e861fea53a5e5cc593ce5130fb';

  static const String abiPath =
      'assets/abi/lab_iot_blockchain.json';

  static bool get isRpcConfigured => rpcUrl.isNotEmpty;
}