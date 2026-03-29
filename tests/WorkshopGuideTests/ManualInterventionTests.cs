// Feature: modernization-workshop, Property 5: Manual intervention coverage
// Validates: Requirements 4.6

using FsCheck;
using FsCheck.Xunit;
using WorkshopGuideTests.Helpers;
using Xunit;

namespace WorkshopGuideTests;

/// <summary>
/// Property 5: Module 2 lab guide contains dedicated remediation subsections
/// for all five intervention areas (OWIN/Identity, EF6→EF Core,
/// Web.Optimization, Web.config→appsettings.json, packages.config→PackageReference).
/// </summary>
public class ManualInterventionTests
{
    /// <summary>
    /// The five manual intervention areas that AWS Transform flags for human review.
    /// Each must have a dedicated subsection in Module 2's Step-by-Step Instructions.
    /// </summary>
    private static readonly (string Name, string[] Keywords)[] InterventionAreas =
    {
        ("OWIN/Identity → ASP.NET Core Identity",
            new[] { "OWIN", "Identity", "ASP.NET Core Identity" }),
        ("EF6 → EF Core + Npgsql",
            new[] { "EF6", "EF Core", "Entity Framework Core", "Npgsql" }),
        ("Web.Optimization → Static File Middleware",
            new[] { "Web.Optimization", "BundleConfig", "static file", "wwwroot" }),
        ("Web.config → appsettings.json",
            new[] { "Web.config", "appsettings.json", "IConfiguration" }),
        ("packages.config → PackageReference",
            new[] { "packages.config", "PackageReference" }),
    };

    /// <summary>
    /// Module 2 must contain a dedicated remediation subsection for each of the
    /// five manual intervention areas flagged by AWS Transform.
    /// </summary>
    [Fact]
    public void Module2_CoversAllFiveManualInterventionAreas()
    {
        var filePath = LabGuideFiles.Module02;
        var instructionsContent = MarkdownParser.GetSectionContent(filePath, "4. Step-by-Step Instructions");

        Assert.False(string.IsNullOrWhiteSpace(instructionsContent),
            "Module 2 has no content in the Step-by-Step Instructions section.");

        foreach (var (name, keywords) in InterventionAreas)
        {
            bool found = keywords.Any(kw =>
                instructionsContent.Contains(kw, StringComparison.OrdinalIgnoreCase));

            Assert.True(found,
                $"Module 2 Step-by-Step Instructions does not contain a remediation " +
                $"subsection for '{name}'. Expected at least one of: {string.Join(", ", keywords)}");
        }
    }

    /// <summary>
    /// Each intervention area should have its own subsection heading (#### level)
    /// in the manual remediation step.
    /// </summary>
    [Fact]
    public void Module2_HasDedicatedSubsectionsForEachInterventionArea()
    {
        var lines = File.ReadAllLines(LabGuideFiles.Module02);

        // Collect all #### headings
        var subHeadings = lines
            .Where(l => l.StartsWith("#### "))
            .Select(l => l[5..].Trim())
            .ToList();

        foreach (var (name, keywords) in InterventionAreas)
        {
            bool hasSubHeading = subHeadings.Any(h =>
                keywords.Any(kw => h.Contains(kw, StringComparison.OrdinalIgnoreCase)));

            Assert.True(hasSubHeading,
                $"Module 2 does not have a dedicated #### subsection heading for '{name}'.");
        }
    }

    /// <summary>
    /// FsCheck property: pick any of the five intervention areas at random —
    /// Module 2 always contains coverage for it.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property Module2AlwaysCoversRandomInterventionArea()
    {
        var areaIndexArb = Arb.From(Gen.Choose(0, InterventionAreas.Length - 1));

        return Prop.ForAll(areaIndexArb, areaIndex =>
        {
            var (_, keywords) = InterventionAreas[areaIndex];
            var instructionsContent = MarkdownParser.GetSectionContent(
                LabGuideFiles.Module02, "4. Step-by-Step Instructions");

            if (string.IsNullOrWhiteSpace(instructionsContent))
                return false;

            return keywords.Any(kw =>
                instructionsContent.Contains(kw, StringComparison.OrdinalIgnoreCase));
        });
    }
}
