# Empty State & UI Components Guide

## Overview
A collection of reusable UI components for handling empty states, loading states, and error states throughout the Hotel Expense Tracker app.

## Components

### 1. EmptyStateWidget
**Location**: [empty_state_widget.dart](lib/widgets/empty_state_widget.dart)

Display friendly empty states when no data is available.

#### Usage
```dart
EmptyStateWidget(
  icon: Icons.receipt_long,
  title: 'No Transactions Yet',
  message: 'Start tracking your expenses and income by adding your first transaction.',
  actionLabel: 'Add Transaction',
  onAction: () {
    // Navigate to add transaction screen
  },
)
```

#### Parameters
- **icon** (IconData, required): Icon to display
- **title** (String, required): Main heading text
- **message** (String, required): Descriptive message
- **actionLabel** (String?, optional): Button text
- **onAction** (VoidCallback?, optional): Button action

#### Visual Design
- Large icon (80px) in light gray
- Bold title (24px font)
- Descriptive message with proper line height
- Optional action button with rounded corners
- Centered layout with padding

### 2. LoadingWidget
**Location**: [empty_state_widget.dart](lib/widgets/empty_state_widget.dart)

Show loading indicators during data fetching or processing.

#### Usage
```dart
LoadingWidget(
  message: 'Loading transactions...',
)
```

#### Parameters
- **message** (String?, optional): Optional loading message

#### Visual Design
- Circular progress indicator
- Optional message below spinner
- Centered layout

### 3. ErrorWidget  
**Location**: [empty_state_widget.dart](lib/widgets/empty_state_widget.dart)

Display error messages with retry options.

#### Usage
```dart
ErrorWidget(
  message: 'Failed to load data. Please check your connection.',
  onRetry: () {
    // Retry loading data
  },
)
```

#### Parameters
- **message** (String, required): Error message to display
- **onRetry** (VoidCallback?, optional): Retry action

#### Visual Design
- Red error icon (80px)
- "Oops! Something went wrong" heading
- Error message text
- Optional retry button

## Use Cases

### Empty Calendar
```dart
// When no transactions exist for a date
EmptyStateWidget(
  icon: Icons.calendar_today,
  title: 'No Activity',
  message: 'No transactions recorded for this day.',
)
```

### Empty Analytics
```dart
// When no analytics data available
EmptyStateWidget(
  icon: Icons.bar_chart,
  title: 'No Analytics Yet',
  message: 'Start adding transactions to see your financial insights and trends.',
  actionLabel: 'Add First Transaction',
  onAction: () => Navigator.push(...),
)
```

### Loading Data
```dart
// While fetching from Supabase
LoadingWidget(
  message: 'Syncing with cloud...',
)
```

### Network Error
```dart
// When API call fails
ErrorWidget(
  message: 'Unable to connect to server. Please check your internet connection.',
  onRetry: () => context.read<TransactionCubit>().loadTransactions(),
)
```

### Permission Denied
```dart
ErrorWidget(
  message: 'Camera permission denied. Please enable it in settings.',
)
```

## Integration Examples

### In a BLoC Builder
```dart
BlocBuilder<TransactionCubit, TransactionState>(
  builder: (context, state) {
    if (state is TransactionLoading) {
      return const LoadingWidget(message: 'Loading transactions...');
    }
    
    if (state is TransactionError) {
      return ErrorWidget(
        message: state.message,
        onRetry: () => context.read<TransactionCubit>().loadTransactions(),
      );
    }
    
    if (state is TransactionLoaded && state.expenses.isEmpty && state.incomes.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No Transactions',
        message: 'Track your first expense or income to get started.',
        actionLabel: 'Add Transaction',
        onAction: () => _navigateToAddTransaction(),
      );
    }
    
    // Show actual data
    return _buildTransactionList(state);
  },
)
```

### In a ListView
```dart
ListView.builder(
  itemCount: transactions.isEmpty ? 1 : transactions.length,
  itemBuilder: (context, index) {
    if (transactions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No Results',
        message: 'No transactions match your search criteria.',
      );
    }
    return TransactionTile(transaction: transactions[index]);
  },
)
```

## Best Practices

### 1. **Consistent Icons**
Use meaningful icons that relate to the content:
- `Icons.receipt_long` - For transactions
- `Icons.calendar_today` - For calendar empty states
- `Icons.bar_chart` - For analytics
- `Icons.search_off` - For search results
- `Icons.wifi_off` - For connectivity issues

### 2. **Clear Messages**
Write helpful, action-oriented messages:
- ✅ "No transactions yet. Add your first one to get started!"
- ❌ "Empty"
- ✅ "Unable to sync. Check your internet connection and try again."
- ❌ "Error"

### 3. **Provide Actions**
Always offer a way forward when possible:
```dart
EmptyStateWidget(
  // ... other params
  actionLabel: 'Add Transaction',  // Clear action
  onAction: () => navigateToAddScreen(),
)
```

### 4. **Handle All States**
Always handle loading, error, and empty states:
```dart
if (isLoading) return LoadingWidget();
if (hasError) return ErrorWidget();
if (isEmpty) return EmptyStateWidget();
return ActualContent();
```

### 5. **Contextual Messages**
Tailor messages to the specific situation:
```dart
// Different contexts
EmptyStateWidget(
  title: 'No Expenses This Month',  // Specific to time period
  message: 'Great! You haven\'t spent anything this month.',
)

EmptyStateWidget(
  title: 'No Food Expenses',  // Specific to category
  message: 'You haven\'t recorded any food expenses yet.',
)
```

## Customization

### Changing Colors
```dart
EmptyStateWidget(
  icon: Icons.check_circle,
  title: 'All Caught Up!',
  message: 'No pending items.',
  // Customize button color
  onAction: () {},
  actionLabel: 'Browse',
)
```

### Adding Custom Styling
```dart
class CustomEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/images/empty_box.png', width: 200),
        EmptyStateWidget(
          icon: Icons.inventory_2,
          title: 'Nothing Here',
          message: 'Your inventory is empty.',
        ),
      ],
    );
  }
}
```

## Accessibility

All components include:
- Semantic labels for screen readers
- Adequate touch targets (48x48dp minimum)
- Proper contrast ratios
- Clear, readable text

## Animation Opportunities

Future enhancements could include:
```dart
// Fade in animation
FadeTransition(
  opacity: animation,
  child: EmptyStateWidget(...),
)

// Scale animation for icon
ScaleTransition(
  scale: animation,
  child: Icon(Icons.check_circle),
)
```

## Testing

### Unit Tests
```dart
testWidgets('EmptyStateWidget shows title and message', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: EmptyStateWidget(
        icon: Icons.test,
        title: 'Test Title',
        message: 'Test Message',
      ),
    ),
  );
  
  expect(find.text('Test Title'), findsOneWidget);
  expect(find.text('Test Message'), findsOneWidget);
  expect(find.byIcon(Icons.test), findsOneWidget);
});
```

---

**Last Updated**: December 2024
**Version**: 1.0.0
