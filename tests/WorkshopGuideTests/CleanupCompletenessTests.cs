// Feature: modernization-workshop, Property 10: Cleanup section resource-command completeness
// Validates: Requirements 9.1, 9.2

using FsCheck;
using FsCheck.Xunit;
using WorkshopGuideTests.Helpers;
using Xunit;

namespace WorkshopGuideTests;

/// <summary>
/// Property 10: For any AWS resource created during a module's instructions,
/// the Cleanup section lists the resource and provides an exact delete command.
/// Checks that the Cleanup section contains AWS CLI delete commands
/// (aws ... delete-...) for key resources created in the step-by-step instructions.
/// </summary>
public class CleanupCompletenessTests
{
    /// <summary>
    /// Key AWS resources created per module that must have corresponding
    /// delete commands in the Cleanup section.
    /// </summary>
    private static readonly Dictionary<string, string[]> ExpectedCleanupResources = new()
    {
        {
            "module-01", new[]
            {
                "delete-replication-task",
                "delete-endpoint",
                "delete-replication-instance",
                "delete-db-instance",
                "delete-db-cluster",
                "delete-db-subnet-group",
            }
        },
        {
            "module-02", new[]
            {
                "delete-connection",
                "delete-transform-job",
            }
        },
        {
            "module-03", new[]
            {
                "delete-repository",
                "delete-secret",
            }
        },
    };

    /// <summary>
    /// For each module, the Cleanup section must contain AWS CLI delete commands
    /// for the key resources created during that module's instructions.
    /// </summary>
    [Fact]
    public void AllModules_CleanupSectionContainsDeleteCommandsForCreatedResources()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var cleanupContent = MarkdownParser.GetSectionContent(filePath, "7. Cleanup");

            Assert.False(string.IsNullOrWhiteSpace(cleanupContent),
                $"File '{fileName}' has no content in the Cleanup section.");

            // Determine which module this is
            var moduleKey = ExpectedCleanupResources.Keys
                .FirstOrDefault(k => fileName.Contains(k, StringComparison.OrdinalIgnoreCase));

            Assert.NotNull(moduleKey);

            foreach (var deleteCommand in ExpectedCleanupResources[moduleKey!])
            {
                Assert.True(
                    cleanupContent.Contains(deleteCommand, StringComparison.OrdinalIgnoreCase),
                    $"File '{fileName}': Cleanup section is missing delete command '{deleteCommand}'.");
            }
        }
    }

    /// <summary>
    /// Every Cleanup section must contain at least one AWS CLI delete command pattern.
    /// </summary>
    [Fact]
    public void AllModules_CleanupSectionContainsAwsCliDeleteCommands()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var cleanupContent = MarkdownParser.GetSectionContent(filePath, "7. Cleanup");

            Assert.False(string.IsNullOrWhiteSpace(cleanupContent),
                $"File '{fileName}' has no content in the Cleanup section.");

            // Must contain at least one "aws ... delete" pattern
            Assert.True(
                cleanupContent.Contains("aws ", StringComparison.OrdinalIgnoreCase) &&
                cleanupContent.Contains("delete", StringComparison.OrdinalIgnoreCase),
                $"File '{fileName}': Cleanup section does not contain any AWS CLI delete commands.");
        }
    }

    /// <summary>
    /// FsCheck property: pick any module at random — its Cleanup section always
    /// contains the expected delete commands for resources created in that module.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property CleanupSectionAlwaysHasDeleteCommandsForCreatedResources()
    {
        var fileIndexArb = Arb.From(Gen.Choose(0, LabGuideFiles.All.Count - 1));

        return Prop.ForAll(fileIndexArb, index =>
        {
            var filePath = LabGuideFiles.All[index];
            var fileName = Path.GetFileName(filePath);
            var cleanupContent = MarkdownParser.GetSectionContent(filePath, "7. Cleanup");

            if (string.IsNullOrWhiteSpace(cleanupContent))
                return false;

            var moduleKey = ExpectedCleanupResources.Keys
                .FirstOrDefault(k => fileName.Contains(k, StringComparison.OrdinalIgnoreCase));

            if (moduleKey is null)
                return false;

            return ExpectedCleanupResources[moduleKey]
                .All(cmd => cleanupContent.Contains(cmd, StringComparison.OrdinalIgnoreCase));
        });
    }
}
