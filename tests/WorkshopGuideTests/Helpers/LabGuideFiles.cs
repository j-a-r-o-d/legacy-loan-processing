namespace WorkshopGuideTests.Helpers;

/// <summary>
/// Provides resolved file paths to the three lab guide Markdown files.
/// Navigates from the test output directory up to the repository root.
/// </summary>
public static class LabGuideFiles
{
    private static readonly Lazy<string> RepoRoot = new(() =>
    {
        // Start from the test assembly's output directory (e.g. bin/Debug/net8.0)
        // and walk up until we find the repo root (identified by the docs/workshop directory).
        var dir = AppContext.BaseDirectory;
        while (dir is not null)
        {
            if (Directory.Exists(Path.Combine(dir, "docs", "workshop")))
                return dir;
            dir = Directory.GetParent(dir)?.FullName;
        }

        throw new DirectoryNotFoundException(
            "Could not locate the repository root from " + AppContext.BaseDirectory);
    });

    public static string Module01 =>
        Path.Combine(RepoRoot.Value, "docs", "workshop", "module-01-database-modernization.md");

    public static string Module02 =>
        Path.Combine(RepoRoot.Value, "docs", "workshop", "module-02-application-modernization.md");

    public static string Module03 =>
        Path.Combine(RepoRoot.Value, "docs", "workshop", "module-03-compute-modernization.md");

    /// <summary>Returns all three lab guide file paths.</summary>
    public static IReadOnlyList<string> All => new[] { Module01, Module02, Module03 };
}
