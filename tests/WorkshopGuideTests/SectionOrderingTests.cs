// Feature: modernization-workshop, Property 1: Lab guide section ordering
// Validates: Requirements 1.2

using FsCheck;
using FsCheck.Xunit;
using WorkshopGuideTests.Helpers;
using Xunit;

namespace WorkshopGuideTests;

/// <summary>
/// Property 1: For any lab guide module, top-level headings appear in order:
/// Overview, Prerequisites, Architecture Diagram, Step-by-Step Instructions,
/// Validation Steps, Troubleshooting, Cleanup.
/// </summary>
public class SectionOrderingTests
{
    private static readonly string[] ExpectedSectionOrder =
    {
        "Overview",
        "Prerequisites",
        "Architecture Diagram",
        "Step-by-Step Instructions",
        "Validation Steps",
        "Troubleshooting",
        "Cleanup"
    };

    /// <summary>
    /// For each lab guide file, parse the top-level headings and verify they
    /// contain the seven required sections in the correct order.
    /// Headings use the format "N. SectionName" — we match on the section name portion.
    /// </summary>
    [Fact]
    public void AllLabGuides_HaveRequiredSectionsInOrder()
    {
        foreach (var filePath in LabGuideFiles.All)
        {
            var headings = MarkdownParser.GetTopLevelHeadings(filePath);

            // Extract just the section name portion after the number prefix (e.g. "1. Overview" → "Overview")
            var sectionNames = headings
                .Select(StripNumberPrefix)
                .ToList();

            // Find the index of each expected section in the parsed headings
            var indices = ExpectedSectionOrder
                .Select(expected => sectionNames.FindIndex(
                    s => s.Equals(expected, StringComparison.OrdinalIgnoreCase)))
                .ToList();

            // All expected sections must be present
            for (int i = 0; i < ExpectedSectionOrder.Length; i++)
            {
                Assert.True(indices[i] >= 0,
                    $"File '{Path.GetFileName(filePath)}' is missing required section: '{ExpectedSectionOrder[i]}'");
            }

            // Sections must appear in strictly increasing order
            for (int i = 1; i < indices.Count; i++)
            {
                Assert.True(indices[i] > indices[i - 1],
                    $"File '{Path.GetFileName(filePath)}': section '{ExpectedSectionOrder[i]}' " +
                    $"must appear after '{ExpectedSectionOrder[i - 1]}'");
            }
        }
    }

    /// <summary>
    /// FsCheck property: pick any lab guide at random — its sections are always in the correct order.
    /// Uses a generator that selects among the three lab guide file indices.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property LabGuideSectionsAreInCorrectOrder()
    {
        var fileIndexArb = Arb.From(Gen.Choose(0, LabGuideFiles.All.Count - 1));

        return Prop.ForAll(fileIndexArb, index =>
        {
            var filePath = LabGuideFiles.All[index];
            var headings = MarkdownParser.GetTopLevelHeadings(filePath);

            var sectionNames = headings
                .Select(StripNumberPrefix)
                .ToList();

            // Every expected section must be present
            foreach (var expected in ExpectedSectionOrder)
            {
                if (!sectionNames.Any(s => s.Equals(expected, StringComparison.OrdinalIgnoreCase)))
                    return false;
            }

            // Sections must appear in strictly increasing index order
            int lastIndex = -1;
            foreach (var expected in ExpectedSectionOrder)
            {
                int idx = sectionNames.FindIndex(
                    s => s.Equals(expected, StringComparison.OrdinalIgnoreCase));
                if (idx <= lastIndex)
                    return false;
                lastIndex = idx;
            }

            return true;
        });
    }

    /// <summary>
    /// Strips a leading number prefix like "1. " or "7. " from a heading text.
    /// Returns the heading unchanged if no prefix is found.
    /// </summary>
    private static string StripNumberPrefix(string heading)
    {
        // Match pattern: one or more digits, a dot, then a space
        int dotIndex = heading.IndexOf(". ", StringComparison.Ordinal);
        if (dotIndex >= 0 && dotIndex <= 3 && heading[..dotIndex].All(char.IsDigit))
        {
            return heading[(dotIndex + 2)..].Trim();
        }

        return heading.Trim();
    }
}
