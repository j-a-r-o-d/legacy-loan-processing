// Feature: modernization-workshop, Property 13: Kiro-assisted code change guidance
// Validates: Requirements 10.1, 10.2, 10.3

using FsCheck;
using FsCheck.Xunit;
using WorkshopGuideTests.Helpers;
using Xunit;

namespace WorkshopGuideTests;

/// <summary>
/// Property 13: For any lab step involving code changes, the guide includes
/// a Kiro prompt callout (🤖), a classification (Kiro-assisted vs manual review),
/// and a review instruction.
/// </summary>
public class KiroPromptGuidanceTests
{
    /// <summary>
    /// Each lab guide that contains code-change steps must include at least one
    /// Kiro prompt callout (🤖 Kiro Prompt).
    /// </summary>
    [Fact]
    public void AllLabGuides_ContainKiroPromptCallouts()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var kiroCallouts = MarkdownParser.GetCalloutBlocks(filePath, "🤖");

            Assert.True(kiroCallouts.Count > 0,
                $"File '{fileName}' does not contain any 🤖 Kiro Prompt callout blocks.");
        }
    }

    /// <summary>
    /// Every lab guide with Kiro prompt callouts must include at least one
    /// classification label indicating whether changes are Kiro-assisted or manual.
    /// </summary>
    [Fact]
    public void AllKiroPromptCallouts_IncludeClassification()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var kiroCallouts = MarkdownParser.GetCalloutBlocks(filePath, "🤖");

            // Read the full file to find classification lines that follow Kiro prompts
            var fullContent = File.ReadAllText(filePath);

            // Every Kiro prompt section should have a Classification nearby
            // Count only lines that start with "> **Classification" pattern
            int classificationCount = CountClassificationLabels(fullContent);

            Assert.True(classificationCount > 0,
                $"File '{fileName}' contains {kiroCallouts.Count} Kiro prompt callouts " +
                $"but no Classification labels.");
        }
    }

    /// <summary>
    /// Every Kiro prompt classification must indicate either "Kiro-assisted" or
    /// "manual review" to guide the attendee.
    /// </summary>
    [Fact]
    public void AllClassifications_IndicateKiroAssistedOrManualReview()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var fullContent = File.ReadAllText(filePath);

            // Find all lines that are actual classification labels
            // (start with "> **Classification" pattern)
            var lines = fullContent.Split('\n');
            var classificationLines = lines
                .Where(l => l.TrimStart().StartsWith("> **Classification", StringComparison.OrdinalIgnoreCase))
                .ToList();

            foreach (var line in classificationLines)
            {
                bool hasKiroAssisted = line.Contains("Kiro-assisted", StringComparison.OrdinalIgnoreCase);
                bool hasManualReview = line.Contains("manual review", StringComparison.OrdinalIgnoreCase);

                Assert.True(hasKiroAssisted || hasManualReview,
                    $"File '{fileName}': Classification line does not indicate 'Kiro-assisted' " +
                    $"or 'manual review': {line.Trim()}");
            }
        }
    }

    /// <summary>
    /// Lab guides with Kiro prompts must include review instructions telling the
    /// attendee to verify Kiro-generated code before proceeding.
    /// </summary>
    [Fact]
    public void AllLabGuides_IncludeReviewInstructions()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var fileName = Path.GetFileName(filePath);
            var fullContent = File.ReadAllText(filePath);

            // Must contain review-related instructions
            bool hasReviewInstruction =
                fullContent.Contains("Review instruction", StringComparison.OrdinalIgnoreCase) ||
                fullContent.Contains("review", StringComparison.OrdinalIgnoreCase) &&
                fullContent.Contains("before proceeding", StringComparison.OrdinalIgnoreCase);

            Assert.True(hasReviewInstruction,
                $"File '{fileName}' does not include review instructions for Kiro-generated code.");
        }
    }

    /// <summary>
    /// FsCheck property: pick any lab guide at random — it always contains Kiro
    /// prompt callouts with classifications and review instructions.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property KiroPromptGuidanceIsAlwaysPresent()
    {
        var fileIndexArb = Arb.From(Gen.Choose(0, LabGuideFiles.All.Count - 1));

        return Prop.ForAll(fileIndexArb, index =>
        {
            var filePath = LabGuideFiles.All[index];
            var fullContent = File.ReadAllText(filePath);
            var kiroCallouts = MarkdownParser.GetCalloutBlocks(filePath, "🤖");

            // Must have at least one Kiro prompt callout
            if (kiroCallouts.Count == 0)
                return false;

            // Must have Classification labels
            var classificationCount = CountClassificationLabels(fullContent);
            if (classificationCount == 0)
                return false;

            // Must have review instructions
            bool hasReview =
                fullContent.Contains("Review instruction", StringComparison.OrdinalIgnoreCase) ||
                (fullContent.Contains("review", StringComparison.OrdinalIgnoreCase) &&
                 fullContent.Contains("before proceeding", StringComparison.OrdinalIgnoreCase));

            return hasReview;
        });
    }

    /// <summary>
    /// Counts case-insensitive occurrences of a substring in a string.
    /// </summary>
    private static int CountOccurrences(string text, string substring)
    {
        int count = 0;
        int index = 0;
        while ((index = text.IndexOf(substring, index, StringComparison.OrdinalIgnoreCase)) >= 0)
        {
            count++;
            index += substring.Length;
        }
        return count;
    }

    /// <summary>
    /// Counts classification labels that follow the "> **Classification" pattern,
    /// which are the actual Kiro prompt classification annotations.
    /// </summary>
    private static int CountClassificationLabels(string text)
    {
        var lines = text.Split('\n');
        return lines.Count(l =>
            l.TrimStart().StartsWith("> **Classification", StringComparison.OrdinalIgnoreCase));
    }
}
