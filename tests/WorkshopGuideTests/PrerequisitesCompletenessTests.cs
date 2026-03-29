// Feature: modernization-workshop, Property 2: Prerequisites completeness
// Validates: Requirements 1.3, 1.4

using FsCheck;
using FsCheck.Xunit;
using WorkshopGuideTests.Helpers;
using Xunit;

namespace WorkshopGuideTests;

/// <summary>
/// Property 2: For any lab guide module, the Prerequisites section mentions
/// AWS services, IAM permissions, required tools with versions, and (for
/// Modules 2/3) expected state from the previous module.
/// </summary>
public class PrerequisitesCompletenessTests
{
    /// <summary>
    /// For each lab guide, the Prerequisites section must contain mentions of
    /// AWS services, IAM permissions, required tools with versions, and
    /// (for Modules 2 and 3) expected starting state from the previous module.
    /// </summary>
    [Fact]
    public void AllLabGuides_HaveCompletePrerequisites()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var prereqContent = MarkdownParser.GetSectionContent(filePath, "2. Prerequisites");

            Assert.False(string.IsNullOrWhiteSpace(prereqContent),
                $"File '{fileName}' has no content in the Prerequisites section.");

            // Must mention AWS services
            Assert.True(
                prereqContent.Contains("AWS", StringComparison.OrdinalIgnoreCase),
                $"File '{fileName}': Prerequisites section does not mention AWS services.");

            // Must mention IAM permissions
            Assert.True(
                prereqContent.Contains("IAM", StringComparison.OrdinalIgnoreCase),
                $"File '{fileName}': Prerequisites section does not mention IAM permissions.");

            // Must mention required tools with versions (look for version patterns)
            Assert.True(
                prereqContent.Contains("Version", StringComparison.OrdinalIgnoreCase) ||
                prereqContent.Contains(">=", StringComparison.Ordinal),
                $"File '{fileName}': Prerequisites section does not mention required tools with versions.");

            // Modules 2 and 3 must reference expected state from previous module
            if (!fileName.Contains("module-01"))
            {
                Assert.True(
                    prereqContent.Contains("Expected Starting State", StringComparison.OrdinalIgnoreCase) ||
                    prereqContent.Contains("previous module", StringComparison.OrdinalIgnoreCase) ||
                    prereqContent.Contains("completed Module", StringComparison.OrdinalIgnoreCase),
                    $"File '{fileName}': Prerequisites section does not reference expected state from previous module.");

                // Must include a verification command (fenced code block)
                Assert.True(
                    prereqContent.Contains("```", StringComparison.Ordinal),
                    $"File '{fileName}': Prerequisites section does not include a verification command.");
            }
        }
    }

    /// <summary>
    /// FsCheck property: pick any lab guide at random — its Prerequisites section
    /// always contains AWS services, IAM permissions, and tools with versions.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property PrerequisitesSectionIsComplete()
    {
        var fileIndexArb = Arb.From(Gen.Choose(0, LabGuideFiles.All.Count - 1));

        return Prop.ForAll(fileIndexArb, index =>
        {
            var filePath = LabGuideFiles.All[index];
            var fileName = Path.GetFileName(filePath);
            var prereqContent = MarkdownParser.GetSectionContent(filePath, "2. Prerequisites");

            if (string.IsNullOrWhiteSpace(prereqContent))
                return false;

            // Must mention AWS services
            if (!prereqContent.Contains("AWS", StringComparison.OrdinalIgnoreCase))
                return false;

            // Must mention IAM permissions
            if (!prereqContent.Contains("IAM", StringComparison.OrdinalIgnoreCase))
                return false;

            // Must mention tools with versions
            if (!prereqContent.Contains("Version", StringComparison.OrdinalIgnoreCase) &&
                !prereqContent.Contains(">=", StringComparison.Ordinal))
                return false;

            // Modules 2 and 3 must reference expected state from previous module
            if (!fileName.Contains("module-01"))
            {
                bool hasExpectedState =
                    prereqContent.Contains("Expected Starting State", StringComparison.OrdinalIgnoreCase) ||
                    prereqContent.Contains("previous module", StringComparison.OrdinalIgnoreCase) ||
                    prereqContent.Contains("completed Module", StringComparison.OrdinalIgnoreCase);

                if (!hasExpectedState)
                    return false;

                // Must include a verification command
                if (!prereqContent.Contains("```", StringComparison.Ordinal))
                    return false;
            }

            return true;
        });
    }
}
