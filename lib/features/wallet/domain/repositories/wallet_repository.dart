import '../entities/wallet.dart';
import '../entities/transaction.dart';

abstract class WalletRepository {
  Future<Wallet> getWallet();
  Future<List<Transaction>> getTransactions(int page, int size);
}
