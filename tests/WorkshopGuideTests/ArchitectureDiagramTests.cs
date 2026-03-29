// Feature: modernization-workshop, Property 3: Architecture diagrams present
// Validates: Requirements 1.5

using FsCheck;
using FsCheck.Xunit;
using WorkshopGuideTests.Helpers;
using Xunit;

namespace WorkshopGuideTests;

/// <summary>
/// Property 3: For any lab guide module, the Architecture Diagram section
/// contains at least two Mermaid code blocks (before and after).
/// </summary>
public class ArchitectureDiagramTests
{
    /// <summary>
    /// For each lab guide, the Architecture Diagram section must contain at least
    /// two Mermaid diagram code blocks — one for the "before" state and one for
    /// the "after" state.
    /// </summary>
    [Fact]
    public void AllLabGuides_HaveBeforeAndAfterArchitectureDiagrams()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var archSection = MarkdownParser.GetSectionContent(filePath, "3. Architecture Diagram");

            Assert.False(string.IsNullOrWhiteSpace(archSection),
                $"File '{fileName}' has no content in the Architecture Diagram section.");

            // Count Mermaid code blocks within the architecture section
            int mermaidCount = CountMermaidBlocks(archSection);

            Assert.True(mermaidCount >= 2,
                $"File '{fileName}': Architecture Diagram section has {mermaidCount} Mermaid " +
                $"diagram(s) but needs at least 2 (before and after).");

            // Verify the section references both before and after states
            Assert.True(
                archSection.Contains("Before", StringComparison.OrdinalIgnoreCase) ||
                archSection.Contains("Current", StringComparison.OrdinalIgnoreCase),
                $"File '{fileName}': Architecture Diagram section does not label a 'Before' or 'Current' diagram.");

            Assert.True(
                archSection.Contains("After", StringComparison.OrdinalIgnoreCase) ||
                archSection.Contains("Target", StringComparison.OrdinalIgnoreCase),
                $"File '{fileName}': Architecture Diagram section does not label an 'After' or 'Target' diagram.");
        }
    }

    /// <summary>
    /// FsCheck property: pick any lab guide at random — its Architecture Diagram
    /// section always contains at least two Mermaid code blocks.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property ArchitectureDiagramSectionHasAtLeastTwoMermaidBlocks()
    {
        var fileIndexArb = Arb.From(Gen.Choose(0, LabGuideFiles.All.Count - 1));

        return Prop.ForAll(fileIndexArb, index =>
        {
            var filePath = LabGuideFiles.All[index];
            var archSection = MarkdownParser.GetSectionContent(filePath, "3. Architecture Diagram");

            if (string.IsNullOrWhiteSpace(archSection))
                return false;

            int mermaidCount = CountMermaidBlocks(archSection);
            if (mermaidCount < 2)
                return false;

            // Must label before/current and after/target
            bool hasBefore = archSection.Contains("Before", StringComparison.OrdinalIgnoreCase) ||
                             archSection.Contains("Current", StringComparison.OrdinalIgnoreCase);
            bool hasAfter = archSection.Contains("After", StringComparison.OrdinalIgnoreCase) ||
                            archSection.Contains("Target", StringComparison.OrdinalIgnoreCase);

            return hasBefore && hasAfter;
        });
    }

    /// <summary>
    /// Counts the number of Mermaid fenced code blocks (```mermaid ... ```) in a string.
    /// </summary>
    private static int CountMermaidBlocks(string content)
    {
        int count = 0;
        var lines = content.Split('\n');
        for (int i = 0; i < lines.Length; i++)
        {
            var trimmed = lines[i].Trim();
            if (trimmed.StartsWith("```mermaid", StringComparison.OrdinalIgnoreCase))
            {
                count++;
            }
        }
        return count;
    }
}
