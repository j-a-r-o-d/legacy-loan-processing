# Module N: [Title]

## 1. Overview

### What You Will Accomplish

[Describe the modernization objective for this module in 2-3 sentences.]

### Estimated Time

[X] minutes

### Key AWS Services Used

- [Service 1]
- [Service 2]
- [Service 3]

---

## 2. Prerequisites

### Required AWS Services and IAM Permissions

| AWS Service | Required IAM Actions |
|---|---|
| [Service] | [actions, e.g., `rds:CreateDBCluster`, `rds:DescribeDBClusters`] |

### Required Tools and Versions

| Tool | Version |
|---|---|
| [Tool name] | [>= X.Y or exact version] |

### Expected Starting State

[Describe the expected state of the application and infrastructure before starting this module. For Modules 2 and 3, reference the output of the previous module.]

```bash
# Verification command — run this to confirm readiness
[command to verify starting state]
```

Expected: [describe what the output should look like]

---

## 3. Architecture Diagram

### Before

```mermaid
graph TB
    subgraph "Current Architecture"
        [Replace with before-state components]
    end
```

### After

```mermaid
graph TB
    subgraph "Target Architecture"
        [Replace with after-state components]
    end
```

---

## 4. Step-by-Step Instructions

### Step N.1: [Action Title]

[Brief description of what this step accomplishes.]

```bash
# AWS CLI command with explicit flags
aws [service] [action] \
    --region us-east-1 \
    --profile workshop \
    --output json \
    [additional parameters]
```

**Console alternative:** [Service] → [Page] → [Action]

Expected output:

```json
{
    "[key]": "[expected value]"
}
```

> **🤖 Kiro Prompt:** [Suggested prompt text for Kiro-assisted code generation or review]

> **⚠️ Manual Review Required:** [Description of what needs human review before proceeding]

### Step N.2: [Action Title]

[Continue with additional steps following the same pattern.]

---

## 5. Validation Steps

### Checkpoint N.1: [What to Verify]

> **✅ Validation Step:** [Description of what is being validated]
> ```bash
> [verification command]
> ```
> Expected: [expected output or result description]

### Checkpoint N.2: [What to Verify]

> **✅ Validation Step:** [Description of what is being validated]
> ```bash
> [verification command]
> ```
> Expected: [expected output or result description]

---

## 6. Troubleshooting

### Common Issue 1: [Error Message or Symptom]

> **🔧 Troubleshooting:** [Error scenario description]
> Cause: [Explanation of the likely cause]
> Fix: [Step-by-step resolution]

### Common Issue 2: [Error Message or Symptom]

> **🔧 Troubleshooting:** [Error scenario description]
> Cause: [Explanation of the likely cause]
> Fix: [Step-by-step resolution]

---

## 7. Cleanup

### Resource Deletion Order

Delete resources in this order to avoid dependency errors:

1. [Dependent resource first]
2. [Parent resource second]
3. [Foundation resource last]

### Deletion Commands

```bash
# Step 1: Delete [resource]
aws [service] [delete-action] \
    --region us-east-1 \
    --profile workshop \
    --output json \
    --[resource-identifier] [value]

# Step 2: Delete [resource]
aws [service] [delete-action] \
    --region us-east-1 \
    --profile workshop \
    --output json \
    --[resource-identifier] [value]
```

### Verification

> **✅ Validation Step:** Confirm all module resources have been removed.
> ```bash
> [verification command to confirm resources are deleted]
> ```
> Expected: [expected output confirming no resources remain]
