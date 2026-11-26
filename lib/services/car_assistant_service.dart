import '../models/backup_car.dart';

/// Frontend contract for the (future) AI car assistant. The real implementation
/// will call a model/API; the UI only ever talks to this interface, so the
/// backend can be swapped in without touching the chat UI.
abstract class CarAssistantService {
  /// Answer a free-text [question] about [car] (nullable when no car selected).
  Future<String> ask(String question, BackupCar? car);
}

/// Placeholder implementation used until the real assistant is wired up.
/// Returns a short canned reply after a brief delay to mimic latency.
class MockCarAssistantService implements CarAssistantService {
  @override
  Future<String> ask(String question, BackupCar? car) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // TODO(assistant): replace with the real model/API call. The UI is already
    // wired to this interface — only this method needs to change.
    final name = car != null ? '${car.brand} ${car.model}' : 'your car';
    return 'AI assistant coming soon — this will answer questions about $name '
        'using your maintenance history.';
  }
}
