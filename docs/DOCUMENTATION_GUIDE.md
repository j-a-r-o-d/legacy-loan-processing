# Documentation Organization Guide

## Overview

This guide explains the documentation structure for the LoanProcessing application and which files to keep for long-term maintenance.

## Essential Documentation (Keep These)

### Core Documentation (Root Level)

These files should remain in the root directory for easy access:

1. **README.md** - Project overview, quick start, and modernization roadmap
2. **DEPLOYMENT.md** - Complete deployment guide for all environments
3. **DATABASE_SETUP.md** - Database setup and maintenance procedures
4. **APPLICATION_CONFIGURATION.md** - Configuration reference for all settings

### Spec Documentation (.kiro/specs/legacy-dotnet-inventory-app/)

Keep these for requirements traceability:

1. **requirements.md** - Functional requirements and acceptance criteria
2. **design.md** - Architecture, design patterns, and technical decisions
3. **tasks.md** - Implementation plan and task tracking

### Component-Specific Documentation

Keep these in their respective directories:

1. **LoanProcessing.Database/README.md** - Database project overview
2. **LoanProcessing.Web/Tests/README.md** - Property-based testing guide
3. **LoanProcessing.Database/StoredProcedures/*.md** - Stored procedure documentation

## Archive These Files

Move these to `docs/archive/` - they were useful during development but aren't needed for maintenance:

### Task Implementation Summaries
- TASK_*_SUMMARY.md (all task summary files)
- TASK_*_IMPLEMENTATION_SUMMARY.md
- TASK_*_VERIFICATION.md
- TASK_*_IMPLEMENTATION_COMPLETE.md

### Checkpoint Files
- CHECKPOINT_*.md
- checkpoint_*.txt

### Test Output Files
- test_*.txt (all test result files)
- *_results.txt
- *_Output.txt

### Setup Files (One-Time Use)
- PROJECT_SETUP.md (initial setup, no longer needed)
- SETUP_COMPLETE.md (setup verification, no longer needed)
- MOVE_TO_LOCAL_DRIVE.md (environment-specific, archive)

### Test Scripts (Move to Tests Directory)
- Test*.ps1 files → Move to `LoanProcessing.Web/Tests/Scripts/`

## Recommended Directory Structure

```
LoanProcessing/
├── README.md                           # Main project documentation
├── DEPLOYMENT.md                       # Deployment guide
├── DATABASE_SETUP.md                   # Database setup guide
├── APPLICATION_CONFIGURATION.md        # Configuration reference
├── .gitignore
├── LoanProcessing.sln
│
├── docs/                               # Documentation directory
│   ├── DOCUMENTATION_GUIDE.md         # This file
│   ├── CONTRIBUTING.md                # Contribution guidelines (create)
│   ├── CHANGELOG.md                   # Version history (create)
│   └── archive/                       # Historical documentation
│       ├── implementation/            # Task summaries
│       ├── checkpoints/               # Checkpoint files
│       └── test-results/              # Test output files
│
├── .kiro/                             # Kiro spec files
│   └── specs/
│       └── legacy-dotnet-inventory-app/
│           ├── requirements.md
│           ├── design.md
│           └── tasks.md
│
├── LoanProcessing.Database/
│   ├── README.md                      # Database project overview
│   ├── Tables/
│   ├── StoredProcedures/
│   │   ├── *.sql
│   │   └── *_README.md               # Keep procedure documentation
│   └── Scripts/
│
└── LoanProcessing.Web/
    ├── Tests/
    │   ├── README.md                  # Testing guide
    │   ├── Scripts/                   # Test PowerShell scripts
    │   │   ├── TestCustomerController.ps1
    │   │   ├── TestLoanController.ps1
    │   │   └── TestReportController.ps1
    │   ├── PropertyTestBase.cs
    │   ├── PropertyTestGenerators.cs
    │   └── SamplePropertyTests.cs
    ├── Controllers/
    ├── Models/
    ├── Views/
    └── Web.config
```

## Files to Delete Completely

These can be safely deleted (no historical value):

- `nuget.exe` (use `dotnet restore` or Visual Studio instead)
- `TestRunner.cs` (if not used)
- Duplicate or temporary test files

## New Files to Create

### 1. CONTRIBUTING.md
Guidelines for contributing to the project:
- Code style guidelines
- Branch naming conventions
- Pull request process
- Testing requirements

### 2. CHANGELOG.md
Version history and release notes:
- Version numbers
- Release dates
- New features
- Bug fixes
- Breaking changes

### 3. docs/TROUBLESHOOTING.md
Common issues and solutions (extracted from DEPLOYMENT.md):
- Database connection issues
- IIS configuration problems
- Build errors
- Runtime errors

## Maintenance Recommendations

### Regular Updates

Update these files when making changes:

1. **README.md** - Update when adding major features
2. **CHANGELOG.md** - Update with every release
3. **DEPLOYMENT.md** - Update when deployment process changes
4. **APPLICATION_CONFIGURATION.md** - Update when adding new settings

### Version Control

Use Git tags for releases:
```bash
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

### Documentation Review

Schedule quarterly reviews to:
- Remove outdated information
- Update screenshots and examples
- Verify all links work
- Check for accuracy

## Quick Reference

### For New Developers
1. Start with **README.md**
2. Follow **DATABASE_SETUP.md**
3. Review **APPLICATION_CONFIGURATION.md**
4. Read **requirements.md** and **design.md**

### For DevOps/Deployment
1. **DEPLOYMENT.md** - Complete deployment guide
2. **DATABASE_SETUP.md** - Database deployment
3. **APPLICATION_CONFIGURATION.md** - Configuration settings

### For Maintenance
1. **design.md** - Architecture and patterns
2. **LoanProcessing.Web/Tests/README.md** - Testing guide
3. **CHANGELOG.md** - Version history

### For Modernization
1. **README.md** - Modernization roadmap
2. **design.md** - Current architecture
3. **requirements.md** - Business requirements

## Summary

**Keep (13 files)**:
- 4 root-level docs (README, DEPLOYMENT, DATABASE_SETUP, APPLICATION_CONFIGURATION)
- 3 spec docs (requirements, design, tasks)
- 3 component docs (Database README, Tests README, stored procedure docs)
- 3 new docs to create (CONTRIBUTING, CHANGELOG, TROUBLESHOOTING)

**Archive (~40 files)**:
- Task summaries and implementation notes
- Checkpoint files
- Test output files
- Setup files

**Move (7 files)**:
- PowerShell test scripts to Tests/Scripts/

**Delete (2 files)**:
- nuget.exe
- Unused test runners

This organization keeps essential documentation accessible while preserving historical context in the archive.
