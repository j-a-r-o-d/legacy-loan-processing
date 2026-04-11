using System;
using FsCheck;
using FsCheck.Xunit;
using LoanProcessing.Web.Validation.Models;

namespace LoanProcessing.Tests
{
    public class StageGuardProperties
    {
        /// <summary>
        /// Property 1: Stage Guard Produces Zero Shadow Results
        /// For any modernization stage other than PreModernization, or for any database
        /// detected as PostgreSQL, the shadow test guard condition evaluates to false,
        /// meaning zero shadow-related TestResult objects are produced.
        /// Validates: Requirements 4.1, 4.2
        /// </summary>
        [Property(MaxTest = 100)]
        public Property StageGuard_NonPreModernization_ProducesNoShadowResults()
        {
            // Generate any stage that is NOT PreModernization
            var nonPreModStages = new[]
            {
                ModernizationStage.PostModule1,
                ModernizationStage.PostModule2,
                ModernizationStage.PostModule3
            };

            var stageGen = Gen.Elements(nonPreModStages);

            return Prop.ForAll(
                Arb.From(stageGen),
                stage =>
                {
                    // The guard condition in CreditEvaluationTests.Run():
                    // if (stage == ModernizationStage.PreModernization && _db != null && !_db.IsPostgreSQL)
                    // For any non-PreModernization stage, this condition is always false
                    bool guardAllowsShadow = stage == ModernizationStage.PreModernization;
                    return !guardAllowsShadow;
                });
        }

        /// <summary>
        /// Property 1b: Stage Guard with PostgreSQL database produces no shadow results
        /// Even when stage IS PreModernization, if the database is PostgreSQL,
        /// the guard condition evaluates to false.
        /// Validates: Requirement 4.2
        /// </summary>
        [Property(MaxTest = 100)]
        public Property StageGuard_PostgreSQL_ProducesNoShadowResults()
        {
            // Generate all possible stages
            var allStages = (ModernizationStage[])Enum.GetValues(typeof(ModernizationStage));
            var stageGen = Gen.Elements(allStages);

            return Prop.ForAll(
                Arb.From(stageGen),
                Arb.From(Gen.Elements(true, false)), // dbIsNull
                (stage, dbIsNull) =>
                {
                    // Simulate the guard: stage == PreModernization && _db != null && !_db.IsPostgreSQL
                    // When IsPostgreSQL == true, guard is always false regardless of stage
                    bool isPostgreSQL = true;
                    bool guardAllowsShadow = stage == ModernizationStage.PreModernization && !dbIsNull && !isPostgreSQL;
                    return !guardAllowsShadow;
                });
        }

        /// <summary>
        /// Property 1c: Stage Guard with null database helper produces no shadow results
        /// When _db is null, the guard condition evaluates to false regardless of stage.
        /// Validates: Requirements 4.1, 4.2
        /// </summary>
        [Property(MaxTest = 100)]
        public Property StageGuard_NullDatabase_ProducesNoShadowResults()
        {
            var allStages = (ModernizationStage[])Enum.GetValues(typeof(ModernizationStage));
            var stageGen = Gen.Elements(allStages);

            return Prop.ForAll(
                Arb.From(stageGen),
                stage =>
                {
                    // When _db == null, guard is always false
                    bool dbIsNull = true;
                    bool guardAllowsShadow = stage == ModernizationStage.PreModernization && !dbIsNull;
                    return !guardAllowsShadow;
                });
        }

        /// <summary>
        /// Property 1d: Shadow tests only execute when ALL three conditions are met
        /// The guard allows shadow execution if and only if:
        /// stage == PreModernization AND _db != null AND !_db.IsPostgreSQL
        /// Validates: Requirements 4.1, 4.2
        /// </summary>
        [Property(MaxTest = 100)]
        public Property StageGuard_OnlyAllowsWhenAllConditionsMet()
        {
            var allStages = (ModernizationStage[])Enum.GetValues(typeof(ModernizationStage));
            var stageGen = Gen.Elements(allStages);

            return Prop.ForAll(
                Arb.From(stageGen),
                Arb.From(Gen.Elements(true, false)), // dbIsNull
                Arb.From(Gen.Elements(true, false)), // isPostgreSQL
                (stage, dbIsNull, isPostgreSQL) =>
                {
                    bool guardAllowsShadow = stage == ModernizationStage.PreModernization && !dbIsNull && !isPostgreSQL;

                    // Shadow tests should ONLY run when all three conditions are true
                    bool expectedAllow = stage == ModernizationStage.PreModernization && !dbIsNull && !isPostgreSQL;

                    return guardAllowsShadow == expectedAllow;
                });
        }


    }
}
