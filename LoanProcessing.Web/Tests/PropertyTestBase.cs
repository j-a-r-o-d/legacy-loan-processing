using System;
using FsCheck;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LoanProcessing.Web.Tests
{
    /// <summary>
    /// Base class for property-based tests using FSCheck.
    /// Provides common configuration and helper methods for all property tests.
    /// </summary>
    [TestClass]
    public abstract class PropertyTestBase
    {
        /// <summary>
        /// Default configuration for property tests.
        /// - MaxTest: 100 iterations per property (as specified in design document)
        /// - QuietOnSuccess: false to show test progress
        /// - Replay: null to use random seed each time
        /// </summary>
        protected static Config DefaultConfig
        {
            get
            {
                var config = Config.Quick;
                return new Config(
                    maxTest: 100,
                    maxFail: config.MaxFail,
                    replay: config.Replay,
                    name: config.Name,
                    startSize: config.StartSize,
                    endSize: config.EndSize,
                    quietOnSuccess: false,
                    every: config.Every,
                    everyShrink: config.EveryShrink,
                    arbitrary: config.Arbitrary,
                    runner: config.Runner
                );
            }
        }

        /// <summary>
        /// Configuration for verbose output during test execution.
        /// </summary>
        protected static Config VerboseConfig
        {
            get
            {
                var config = DefaultConfig;
                return new Config(
                    maxTest: config.MaxTest,
                    maxFail: config.MaxFail,
                    replay: config.Replay,
                    name: config.Name,
                    startSize: config.StartSize,
                    endSize: config.EndSize,
                    quietOnSuccess: false,
                    every: Config.Verbose.Every,
                    everyShrink: Config.Verbose.EveryShrink,
                    arbitrary: config.Arbitrary,
                    runner: config.Runner
                );
            }
        }

        /// <summary>
        /// Configuration for quick testing during development (fewer iterations).
        /// </summary>
        protected static Config QuickConfig
        {
            get
            {
                var config = Config.Quick;
                return new Config(
                    maxTest: 10,
                    maxFail: config.MaxFail,
                    replay: config.Replay,
                    name: config.Name,
                    startSize: config.StartSize,
                    endSize: config.EndSize,
                    quietOnSuccess: false,
                    every: config.Every,
                    everyShrink: config.EveryShrink,
                    arbitrary: config.Arbitrary,
                    runner: config.Runner
                );
            }
        }

        /// <summary>
        /// Runs a property test with the default configuration.
        /// Throws an exception if the property fails for any generated input.
        /// </summary>
        /// <param name="property">The property to test</param>
        /// <param name="propertyName">Name of the property for error reporting</param>
        protected void CheckProperty(Property property, string propertyName = "Property")
        {
            try
            {
                Check.One(DefaultConfig, property);
            }
            catch (Exception ex)
            {
                Assert.Fail($"{propertyName} failed: {ex.Message}");
            }
        }

        /// <summary>
        /// Runs a property test with custom configuration.
        /// </summary>
        /// <param name="config">FSCheck configuration</param>
        /// <param name="property">The property to test</param>
        /// <param name="propertyName">Name of the property for error reporting</param>
        protected void CheckProperty(Config config, Property property, string propertyName = "Property")
        {
            try
            {
                Check.One(config, property);
            }
            catch (Exception ex)
            {
                Assert.Fail($"{propertyName} failed: {ex.Message}");
            }
        }

        /// <summary>
        /// Runs a boolean property test with the default configuration.
        /// </summary>
        /// <typeparam name="T">Type of the generated input</typeparam>
        /// <param name="arbitrary">Generator for test inputs</param>
        /// <param name="predicate">Property predicate that should hold for all inputs</param>
        /// <param name="propertyName">Name of the property for error reporting</param>
        protected void CheckProperty<T>(Arbitrary<T> arbitrary, Func<T, bool> predicate, string propertyName = "Property")
        {
            var property = Prop.ForAll(arbitrary, predicate);
            CheckProperty(property, propertyName);
        }

        /// <summary>
        /// Runs a property test that returns a Property result.
        /// </summary>
        /// <typeparam name="T">Type of the generated input</typeparam>
        /// <param name="arbitrary">Generator for test inputs</param>
        /// <param name="propertyFunc">Function that returns a Property for each input</param>
        /// <param name="propertyName">Name of the property for error reporting</param>
        protected void CheckProperty<T>(Arbitrary<T> arbitrary, Func<T, Property> propertyFunc, string propertyName = "Property")
        {
            var property = Prop.ForAll(arbitrary, propertyFunc);
            CheckProperty(property, propertyName);
        }

        /// <summary>
        /// Helper method to assert that a decimal value is approximately equal to another,
        /// accounting for floating-point precision issues.
        /// </summary>
        /// <param name="expected">Expected value</param>
        /// <param name="actual">Actual value</param>
        /// <param name="tolerance">Maximum allowed difference (default: 0.01)</param>
        /// <returns>True if values are approximately equal</returns>
        protected bool ApproximatelyEqual(decimal expected, decimal actual, decimal tolerance = 0.01m)
        {
            return Math.Abs(expected - actual) <= tolerance;
        }

        /// <summary>
        /// Helper method to assert that a value is within a specified range.
        /// </summary>
        /// <typeparam name="T">Type of the value (must be comparable)</typeparam>
        /// <param name="value">Value to check</param>
        /// <param name="min">Minimum allowed value (inclusive)</param>
        /// <param name="max">Maximum allowed value (inclusive)</param>
        /// <returns>True if value is within range</returns>
        protected bool InRange<T>(T value, T min, T max) where T : IComparable<T>
        {
            return value.CompareTo(min) >= 0 && value.CompareTo(max) <= 0;
        }

        /// <summary>
        /// Helper method to format a property test tag according to the design document specification.
        /// Format: "Feature: legacy-dotnet-inventory-app, Property {number}: {property_text}"
        /// </summary>
        /// <param name="propertyNumber">Property number from design document</param>
        /// <param name="propertyText">Brief description of the property</param>
        /// <returns>Formatted property tag</returns>
        protected string FormatPropertyTag(int propertyNumber, string propertyText)
        {
            return $"Feature: legacy-dotnet-inventory-app, Property {propertyNumber}: {propertyText}";
        }

        /// <summary>
        /// Logs a message during property test execution.
        /// Useful for debugging failing tests.
        /// </summary>
        /// <param name="message">Message to log</param>
        protected void LogTestMessage(string message)
        {
            Console.WriteLine($"[PropertyTest] {DateTime.Now:HH:mm:ss.fff} - {message}");
        }
    }
}
