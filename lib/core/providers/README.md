# Riverpod Provider Patterns for TourVN

> **Reference Documentation** for all TourVN developers implementing features with Riverpod 3.2.0

This guide establishes **mandatory patterns** for state management across all features. These patterns ensure consistency, testability, and maintainability throughout the codebase.

---

## 📋 Table of Contents

1. [Provider Naming Conventions](#provider-naming-conventions)
2. [Provider Types Decision Guide](#provider-types-decision-guide)
3. [AsyncNotifier Pattern (Most Common)](#asyncnotifier-pattern)
4. [StreamProvider Pattern](#streamprovider-pattern)
5. [StateProvider Pattern](#stateprovider-pattern)
6. [Provider Pattern](#provider-pattern)
5. [AutoDispose Best Practices](#autodispose-best-practices)
7. [Error Handling](#error-handling)
8. [Testing Providers](#testing-providers)

---

## 🎯 Provider Naming Conventions

**MANDATORY conventions as per `architecture.md#Communication-Patterns`:**

### Data Providers
Pattern: `[feature]Provider`

```dart
// ✅ GOOD
final destinationsProvider = AsyncNotifierProvider<...>(...);
final authStateProvider = StreamProvider<User?>(...)  
final tripsProvider = AsyncNotifierProvider<...>(...);

// ❌ BAD
final DestinationsProvider = ...;  // Wrong case
final get_destinations = ...;      // Snake case
final destProvider = ...;          // Abbreviated
```

### State Providers
Pattern: `[action][Feature]Provider`

```dart
// ✅ GOOD
final selectedDestinationProvider = StateProvider<Destination?>(...);;
final currentTripDayProvider = StateProvider<int>(...);
final tripDaysProvider = StateProvider<List<TripDay>>(...);

// ❌ BAD
final destination = StateProvider...;  // Missing Provider suffix
final selected_dest = ...;             // Snake case
```

### Notifier Classes
Pattern: `[Feature]Notifier`

```dart
// ✅ GOOD
class TripsNotifier extends AsyncNotifier<List<Trip>> {}
class DestinationsNotifier extends AsyncNotifier<List<Destination>> {}

// ❌ BAD
class trips_notifier extends AsyncNotifier<...> {}  // Wrong case
class TripController extends AsyncNotifier<...> {}  // Wrong suffix
```

### Repository Providers
Pattern: `[feature]RepositoryProvider`

```dart
// ✅ GOOD
final tripRepositoryProvider = Provider<TripRepository>(...);
final authRepositoryProvider = Provider<AuthRepository>(...);

// ❌ BAD
final tripRepo = Provider...;  // Missing full name
final TripRepositoryProvider = ...;  // Wrong case
```

---

## 🔀 Provider Types Decision Guide

**Flowchart for choosing the right provider type:**

```
Is it async data from backend?
├── Yes → Need real-time updates?
│   ├── Yes → StreamProvider ✓
│   │   Examples: Auth state, real-time trip sync
│   └── No → AsyncNotifierProvider ✓
│       Examples: Fetch trips, destinations, reviews
└── No → Need mutation?
    ├── Yes → StateProvider ✓
    │   Examples: Selected destination, current tab
    └── No → Provider ✓
        Examples: Repositories, services, constants
```

### Quick Reference Table

| Provider Type | Use Case | Mutability | Async | Example |
|--------------|----------|------------|-------|---------|
| **AsyncNotifierProvider** | Async CRUD operations | ✅ Mutable | ✅ Async | Trips, Destinations, Reviews |
| **StreamProvider** | Real-time updates | ❌ Read-only | ✅ Async | Auth state, Firestore listeners |
| **StateProvider** | Simple UI state | ✅ Mutable | ❌ Sync | Selected item, filters, tab index |
| **Provider** | Dependencies, computed values | ❌ Immutable | ❌ Sync | Repositories, services |

---

## 🏗️ AsyncNotifier Pattern

**Most common pattern for features** - Use for async CRUD operations.

### Complete Implementation Example

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Repository Provider (dependency)
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

// 2. AsyncNotifier Class
class TripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    // Initial data load - called automatically
    try {
      final repository = ref.read(tripRepositoryProvider);
      final userId = ref.watch(authStateProvider).value?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      return await repository.getTrips(userId);
    } catch (e) {
      rethrow; // Error caught by AsyncValue
    }
  }

  // Action: Create trip
  Future<void> createTrip(Trip trip) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.createTrip(trip);
      return build(); // Refresh list
    });
  }

  // Action: Update trip
  Future<void> updateTrip(Trip trip) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.updateTrip(trip);
      return build();
    });
  }

  // Action: Delete trip
  Future<void> deleteTrip(String tripId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.deleteTrip(tripId);
      return build();
    });
  }
}

// 3. Provider Definition
final tripsProvider = AsyncNotifierProvider<TripsNotifier, List<Trip>>(() {
  return TripsNotifier();
});
```

### UI Consumption with ConsumerWidget

```dart
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return tripsAsync.when(
      data: (trips) => TripsList(trips: trips),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}

// Calling actions
ref.read(tripsProvider.notifier).createTrip(newTrip);
ref.read(tripsProvider.notifier).deleteTrip(tripId);
```

### Key Principles

1. **build()** - Called automatically on first access, returns initial data
2. **AsyncValue.guard()** - Wraps async operations for automatic error handling
3. **ref.read()** - Use for one-time reads (repositories, actions)
4. **ref.watch()** - Use for reactive dependencies
5. **Return build()** - Refresh state after mutations

---

## 🌊 StreamProvider Pattern

**For real-time updates** - Use for Firestore listeners and auth state.

### Implementation Example

```dart
// Auth state provider - listens to Firebase Auth changes
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = FirebaseAuth.instance;
  return auth.authStateChanges();
});

// Real-time trip sync
final currentTripProvider = StreamProvider.family<Trip, String>((ref, tripId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('trips')
      .doc(tripId)
      .snapshots()
      .map((snapshot) => Trip.fromFirestore(snapshot));
});
```

### UI Consumption

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return LoginPrompt();
        return UserProfile(user: user);
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => ErrorWidget(error: error),
    );
  }
}
```

---

## 📦 StateProvider Pattern

**For simple mutable state** - UI state, selections, filters.

### Implementation Example

```dart
// Selected destination
final selectedDestinationProvider = StateProvider<Destination?>((ref) => null);

// Current tab index
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

// Search filter
final searchQueryProvider = StateProvider<String>((ref) => '');
```

### UI Consumption

```dart
class DestinationHub extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDest = ref.watch(selectedDestinationProvider);

    return Column(
      children: [
        DestinationList(
          onTap: (destination) {
            // Update state
            ref.read(selectedDestinationProvider.notifier).state = destination;
          },
        ),
        if (selectedDest != null)
          DestinationDetail(destination: selectedDest),
      ],
    );
  }
}
```

---

## 🔧 Provider Pattern

**For dependencies and computed values** - Repositories, services, constants.

### Implementation Example

```dart
// Repository providers
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final firestore = ref.read(firestoreProvider);
  return TripRepository(firestore);
});

// Computed value
final tripCountProvider = Provider<int>((ref) {
  final trips = ref.watch(tripsProvider).valueOrNull ?? [];
  return trips.length;
});
```

---

## ♻️ AutoDispose Best Practices

**When to use `.autoDispose`:**

### Use AutoDispose For:
- ✅ Screen-specific state that should be cleaned up on navigation
- ✅ Temporary filters or search queries
- ✅ Detail views that fetch data by ID

```dart
// ✅ GOOD - Auto-dispose when leaving screen
final destinationDetailProvider = FutureProvider.family.autoDispose<Destination, String>(
  (ref, destinationId) async {
    final repository = ref.read(destinationRepositoryProvider);
    return repository.getDestination(destinationId);
  },
);

// ✅ GOOD - Search state disposed when leaving search screen
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
```

### Do NOT Use AutoDispose For:
- ❌ Global app state (auth, theme)
- ❌ Persistent data (trips list, user profile)
- ❌ Repositories and services

```dart
// ✅ GOOD - Keep auth state alive
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ❌ BAD - Would dispose trips when navigating away
final tripsProvider = AsyncNotifierProvider.autoDispose<...>(...); // DON'T
```

---

## ⚠️ Error Handling

### AsyncValue.guard() Pattern

```dart
Future<void> createTrip(Trip trip) async {
  state = await AsyncValue.guard(() async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.createTrip(trip);
    return build();
  });
  
  // If error occurs:
  // - state becomes AsyncError
  // - .when() in UI shows error callback
  // - No need for try-catch here
}
```

### UI Error Display

```dart
tripsAsync.when(
  data: (trips) => TripsList(trips: trips),
  loading: () => const LoadingIndicator(),
  error: (error, stack) {
    // Display user-friendly Vietnamese error message
    final message = error is AppException 
        ? error.message 
        : 'Đã xảy ra lỗi. Vui lòng thử lại.';
    
    return ErrorWidget(
      message: message,
      onRetry: () => ref.invalidate(tripsProvider),
    );
  },
);
```

---

## 🧪 Testing Providers

### Override Providers in Tests

```dart
testWidgets('TripsScreen displays trips', (tester) async {
  final mockRepository = MockTripRepository();
  when(mockRepository.getTrips(any)).thenAnswer((_) async => [
    Trip(id: '1', name: 'Test Trip'),
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(home: TripsScreen()),
    ),
  );

  expect(find.text('Test Trip'), findsOneWidget);
});
```

---

## 📚 Additional Resources

- [Official Riverpod Docs](https://riverpod.dev)
- [AsyncNotifier Guide](https://riverpod.dev/docs/concepts/providers/async_notifier_provider)
- [Architecture Document](../../../_bmad-output/planning-artifacts/architecture.md#Communication-Patterns)
- [Project Context](../../../_bmad-output/planning-artifacts/project-context.md#Framework-Specific-Rules)
- [Example Implementation](../features/example/presentation/providers/example_provider.dart)

---

## ✅ Checklist for New Providers

Before creating a new provider, verify:

- [ ] Provider name follows [feature]Provider convention
- [ ] Correct provider type chosen (AsyncNotifier, Stream, State, or Provider)
- [ ] Repository injected via Provider (not instantiated directly)
- [ ] AsyncValue.guard() used for error handling
- [ ] AutoDispose considered (and applied if appropriate)
- [ ] ConsumerWidget used in UI (not StatefulWidget)
- [ ] Tests written with provider overrides

---

**Last Updated:** 2026-01-26  
**Riverpod Version:** 3.2.0  
**Author:** TourVN Development Team
