namespace WorkshopGuideTests.Helpers;

/// <summary>
/// Simple regex/string-based Markdown parser that extracts structural elements
/// from the workshop lab guide files. Not a general-purpose Markdown parser —
/// handles only the patterns used in the lab guides.
/// </summary>
public static class MarkdownParser
{
    /// <summary>
    /// Returns an ordered list of top-level (##) heading texts from the file.
    /// Strips the leading "## " and any trailing whitespace.
    /// </summary>
    public static List<string> GetTopLevelHeadings(string filePath)
    {
        var lines = File.ReadAllLines(filePath);
        var headings = new List<string>();

        foreach (var line in lines)
        {
            // Match lines that start with exactly "## " (not "### " etc.)
            if (line.StartsWith("## ") && !line.StartsWith("### "))
            {
                headings.Add(line[3..].Trim());
            }
        }

        return headings;
    }

    /// <summary>
    /// Returns all fenced code blocks as (language, content) tuples.
    /// Language is the info string after the opening ```, or empty string if none.
    /// </summary>
    public static List<(string Language, string Content)> GetFencedCodeBlocks(string filePath)
    {
        var lines = File.ReadAllLines(filePath);
        var blocks = new List<(string Language, string Content)>();
        string? currentLang = null;
        var contentLines = new List<string>();

        foreach (var line in lines)
        {
            if (currentLang is null)
            {
                // Look for opening fence: ``` optionally followed by language tag
                // Also handle blockquote-prefixed fences: > ```lang
                var trimmed = line.TrimStart();
                if (trimmed.StartsWith("> "))
                    trimmed = trimmed[2..].TrimStart();

                if (trimmed.StartsWith("```") && !trimmed.Substring(3).TrimEnd().Contains('`'))
                {
                    currentLang = trimmed[3..].Trim();
                    contentLines.Clear();
                }
            }
            else
            {
                // Look for closing fence
                var trimmed = line.TrimStart();
                if (trimmed.StartsWith("> "))
                    trimmed = trimmed[2..].TrimStart();

                if (trimmed == "```")
                {
                    blocks.Add((currentLang, string.Join("\n", contentLines)));
                    currentLang = null;
                }
                else
                {
                    // Strip leading "> " from blockquote-embedded code blocks
                    var contentLine = line;
                    if (contentLine.StartsWith("> "))
                        contentLine = contentLine[2..];

                    contentLines.Add(contentLine);
                }
            }
        }

        return blocks;
    }

    /// <summary>
    /// Returns all Mermaid diagram code blocks (fenced blocks with language "mermaid").
    /// </summary>
    public static List<string> GetMermaidDiagrams(string filePath)
    {
        return GetFencedCodeBlocks(filePath)
            .Where(b => b.Language.Equals("mermaid", StringComparison.OrdinalIgnoreCase))
            .Select(b => b.Content)
            .ToList();
    }

    /// <summary>
    /// Returns callout blocks matching a specific callout type emoji/prefix.
    /// Callout blocks start with lines like: > **✅ Validation Step:** ...
    /// The calloutType should be the emoji prefix, e.g. "✅", "🔧", "🤖", "⚠️".
    /// Returns the full text of each callout block (consecutive lines starting with >).
    /// </summary>
    public static List<string> GetCalloutBlocks(string filePath, string calloutType)
    {
        var lines = File.ReadAllLines(filePath);
        var blocks = new List<string>();
        var currentBlock = new List<string>();
        bool inMatchingCallout = false;

        for (int i = 0; i < lines.Length; i++)
        {
            var line = lines[i];

            if (!inMatchingCallout)
            {
                // Check if this line starts a matching callout
                if (line.StartsWith("> **") && line.Contains(calloutType))
                {
                    inMatchingCallout = true;
                    currentBlock.Clear();
                    currentBlock.Add(line);
                }
            }
            else
            {
                // Continue collecting blockquote lines
                if (line.StartsWith(">"))
                {
                    currentBlock.Add(line);
                }
                else
                {
                    // End of blockquote — save and reset
                    blocks.Add(string.Join("\n", currentBlock));
                    currentBlock.Clear();
                    inMatchingCallout = false;

                    // Check if this new line starts another matching callout
                    if (line.StartsWith("> **") && line.Contains(calloutType))
                    {
                        inMatchingCallout = true;
                        currentBlock.Add(line);
                    }
                }
            }
        }

        // Flush any remaining block
        if (inMatchingCallout && currentBlock.Count > 0)
        {
            blocks.Add(string.Join("\n", currentBlock));
        }

        return blocks;
    }

    /// <summary>
    /// Returns all content under a specific ## heading until the next ## heading or end of file.
    /// The heading text should match exactly (case-sensitive) after stripping "## ".
    /// </summary>
    public static string GetSectionContent(string filePath, string sectionHeading)
    {
        var lines = File.ReadAllLines(filePath);
        var contentLines = new List<string>();
        bool inSection = false;

        foreach (var line in lines)
        {
            if (line.StartsWith("## ") && !line.StartsWith("### "))
            {
                if (inSection)
                    break; // Hit the next ## heading — stop

                var heading = line[3..].Trim();
                if (heading == sectionHeading)
                {
                    inSection = true;
                    continue; // Skip the heading line itself
                }
            }
            else if (inSection)
            {
                contentLines.Add(line);
            }
        }

        return string.Join("\n", contentLines).Trim();
    }
}
