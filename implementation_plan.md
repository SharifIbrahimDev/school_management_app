# Implementation Plan: Production Readiness

This plan addresses the critical mock data and stubbed functionality identified in the application assessment.

## Phase 1: Enable Real Payments (High Priority)
**Objective**: Allow parents to successfully pay fees using Paystack.

1.  **Configure Environment**:
    *   Create/Verify a secure config for the Paystack Public Key (do not hardcode in production).
2.  **Un-stub `parent_fee_screen.dart`**:
    *   Uncomment the `plugin.initialize` call in `initState`.
    *   Uncomment the `plugin.checkout` call in `_initiatePayment`.
    *   Ensure the `CheckoutResponse` is handled correctly (success/failure/cancellation).
    *   Ensure the `reference` from backend initialization is passed to the checkout.

## Phase 2: Wire Up Analytics Dashboard
**Objective**: Replace hardcoded charts in `AnalyticsDashboardScreen` with real data from `ReportServiceApi`.

1.  **Enhance `ReportServiceApi`**:
    *   Verify/Add `getFinancialSummary()` returns total income, expenses, profit.
    *   Add `getFeeCollectionTrend(year)` to return monthly data points for the trend chart.
    *   Add `getExpenseDistribution()` to return data for the pie chart.
2.  **Refactor `AnalyticsDashboardScreen`**:
    *   Convert to `FutureBuilder` or use `initState` to fetch data.
    *   Replace static `FlSpot` list with mapped data from API.
    *   Replace static Pie Chart sections with data from API.
    *   Replace static "Recent Transactions" list with `TransactionServiceApi.getRecent()`.

## Phase 3: Dynamic Parent Dashboard
**Objective**: Show real-time attendance and academic progress on the Parent Dashboard.

1.  **Enhance `AttendanceServiceApi`**:
    *   Add `getStudentAttendanceSummary(int studentId, int termId)` to return:
        *   `present_count`
        *   `total_days`
        *   `percentage`
2.  **Enhance `ExamServiceApi`**:
    *   Add `getStudentRecentResults(int studentId, {int limit = 3})` to return the latest graded exams.
3.  **Update `ParentDashboardWidget`**:
    *   In `_loadData` (or a new specific loader), fetch these stats for each student.
    *   Pass this data to the `AttendanceCircleChart` and `ResultProgressBar`.

## Phase 4: Verification
1.  **Integration Testing**:
    *   Perform a test payment (using Paystack Test Card).
    *   Verify dashboard numbers update after the payment.
2.  **Code Analysis**:
    *   Run `flutter analyze` to ensure no new issues were introduced.
