-- ============================================================================
-- Master Test Script: Run All Repository Tests
-- Description: Executes all repository tests for checkpoint 12 verification
-- Task: 12. Checkpoint - Verify data access and service layers
-- ============================================================================

USE LoanProcessing;
GO

PRINT '============================================================================';
PRINT 'CHECKPOINT 12: VERIFY DATA ACCESS AND SERVICE LAYERS';
PRINT '============================================================================';
PRINT '';
PRINT 'This script will test all repository implementations created in Task 10:';
PRINT '  - Task 10.1: ICustomerRepository';
PRINT '  - Task 10.2: ILoanApplicationRepository';
PRINT '  - Task 10.3: ILoanDecisionRepository';
PRINT '  - Task 10.4: IPaymentScheduleRepository';
PRINT '  - Task 10.5: IReportRepository';
PRINT '';
PRINT 'Starting tests at: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '';
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: Customer Repository (Task 10.1)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 1: TESTING CUSTOMER REPOSITORY (TASK 10.1)';
PRINT '============================================================================';
PRINT '';

:r TestCustomerRepository.sql

-- ============================================================================
-- SECTION 2: Loan Application Repository (Task 10.2)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 2: TESTING LOAN APPLICATION REPOSITORY (TASK 10.2)';
PRINT '============================================================================';
PRINT '';

:r TestLoanApplicationRepository.sql

-- ============================================================================
-- SECTION 3: Loan Decision Repository (Task 10.3)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 3: TESTING LOAN DECISION REPOSITORY (TASK 10.3)';
PRINT '============================================================================';
PRINT '';

:r TestLoanDecisionRepository.sql

-- ============================================================================
-- SECTION 4: Payment Schedule Repository (Task 10.4)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 4: TESTING PAYMENT SCHEDULE REPOSITORY (TASK 10.4)';
PRINT '============================================================================';
PRINT '';

:r TestPaymentScheduleRepository.sql

-- ============================================================================
-- SECTION 5: Report Repository (Task 10.5)
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'SECTION 5: TESTING REPORT REPOSITORY (TASK 10.5)';
PRINT '============================================================================';
PRINT '';

:r TestReportRepository.sql

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'CHECKPOINT 12: TEST EXECUTION COMPLETE';
PRINT '============================================================================';
PRINT '';
PRINT 'All repository tests have been executed.';
PRINT 'Completed at: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '';
PRINT 'Summary of tested repositories:';
PRINT '';
PRINT 'Data Access Layer (Task 10):';
PRINT '  ✓ ICustomerRepository - GetById, Search, CreateCustomer, UpdateCustomer';
PRINT '  ✓ ILoanApplicationRepository - SubmitApplication, GetById, GetByCustomer';
PRINT '  ✓ ILoanDecisionRepository - EvaluateCredit, ProcessDecision, GetByApplication';
PRINT '  ✓ IPaymentScheduleRepository - GetScheduleByApplication, CalculateSchedule';
PRINT '  ✓ IReportRepository - GeneratePortfolioReport';
PRINT '';
PRINT 'Please review the output above for any failures or errors.';
PRINT 'If all tests passed, the data access layer is working correctly.';
PRINT '';
PRINT 'Next Steps:';
PRINT '  - Verify service layer tests (Task 11)';
PRINT '  - Build the solution to ensure no compilation errors';
PRINT '  - Run any available unit tests for service layer';
PRINT '';
PRINT '============================================================================';
GO
