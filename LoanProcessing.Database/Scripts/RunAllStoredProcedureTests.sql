-- ============================================================================
-- Master Test Script: Run All Stored Procedure Tests
-- Description: Executes all stored procedure tests for checkpoint verification
-- Task: 8. Checkpoint - Verify all stored procedures
-- ============================================================================

USE LoanProcessing;
GO

PRINT '============================================================================';
PRINT 'CHECKPOINT 8: VERIFY ALL STORED PROCEDURES';
PRINT '============================================================================';
PRINT '';
PRINT 'This script will test all stored procedures created in Tasks 3, 5, 6, and 7:';
PRINT '  - Task 3: Customer Management Stored Procedures';
PRINT '  - Task 5: Loan Application Stored Procedures';
PRINT '  - Task 6: Loan Decision and Payment Schedule Stored Procedures';
PRINT '  - Task 7: Reporting Stored Procedures';
PRINT '';
PRINT 'Starting tests at: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '';
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: Customer Management Stored Procedures (Task 3)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 1: TESTING CUSTOMER MANAGEMENT STORED PROCEDURES (TASK 3)';
PRINT '============================================================================';
PRINT '';

:r TestCustomerProcedures.sql

-- ============================================================================
-- SECTION 2: Loan Application Stored Procedures (Task 5)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 2: TESTING LOAN APPLICATION STORED PROCEDURES (TASK 5)';
PRINT '============================================================================';
PRINT '';

:r TestLoanApplicationProcedures.sql

-- ============================================================================
-- SECTION 3: Credit Evaluation Stored Procedure (Task 5)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 3: TESTING CREDIT EVALUATION STORED PROCEDURE (TASK 5)';
PRINT '============================================================================';
PRINT '';

:r TestCreditEvaluation.sql

-- ============================================================================
-- SECTION 4: Payment Schedule Calculation Stored Procedure (Task 6)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 4: TESTING PAYMENT SCHEDULE CALCULATION (TASK 6)';
PRINT '============================================================================';
PRINT '';

:r TestCalculatePaymentSchedule.sql

-- ============================================================================
-- SECTION 5: Portfolio Report Generation Stored Procedure (Task 7)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 5: TESTING PORTFOLIO REPORT GENERATION (TASK 7)';
PRINT '============================================================================';
PRINT '';

:r TestGeneratePortfolioReport.sql

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'CHECKPOINT 8: TEST EXECUTION COMPLETE';
PRINT '============================================================================';
PRINT '';
PRINT 'All stored procedure tests have been executed.';
PRINT 'Completed at: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '';
PRINT 'Summary of tested stored procedures:';
PRINT '';
PRINT 'Customer Management (Task 3):';
PRINT '  ✓ sp_CreateCustomer';
PRINT '  ✓ sp_GetCustomerById';
PRINT '  ✓ sp_UpdateCustomer';
PRINT '  ✓ sp_SearchCustomers';
PRINT '';
PRINT 'Loan Application (Task 5):';
PRINT '  ✓ sp_SubmitLoanApplication';
PRINT '  ✓ sp_EvaluateCredit';
PRINT '';
PRINT 'Loan Decision & Payment Schedule (Task 6):';
PRINT '  ✓ sp_ProcessLoanDecision';
PRINT '  ✓ sp_CalculatePaymentSchedule';
PRINT '';
PRINT 'Reporting (Task 7):';
PRINT '  ✓ sp_GeneratePortfolioReport';
PRINT '';
PRINT 'Please review the output above for any failures or errors.';
PRINT 'If all tests passed, the stored procedures are working correctly.';
PRINT '';
PRINT '============================================================================';
GO
