using System;
using FsCheck;
using FsCheck.Xunit;
using LoanProcessing.Web.Services;

namespace LoanProcessing.Tests
{
    public class CreditEvaluationCalculatorProperties
    {
        [Property(MaxTest = 100)]
        public Property DtiRatio_MatchesFormula()
        {
            return Prop.ForAll(
                Arb.From(Gen.Choose(0, 500000).Select(x => (decimal)x)),
                Arb.From(Gen.Choose(0, 500000).Select(x => (decimal)x)),
                Arb.From(Gen.Choose(1, 500000).Select(x => (decimal)x)),
                (existingDebt, requestedAmount, annualIncome) =>
                {
                    decimal expected = Math.Round(((existingDebt + requestedAmount) / annualIncome) * 100, 4);
                    decimal actual = CreditEvaluationCalculator.CalculateDtiRatio(existingDebt, requestedAmount, annualIncome);
                    return actual == expected;
                });
        }

        [Property(MaxTest = 100)]
        public Property CreditScoreComponent_ReturnsValidBracket()
        {
            return Prop.ForAll(
                Arb.From(Gen.Choose(300, 850)),
                creditScore =>
                {
                    int result = CreditEvaluationCalculator.CalculateCreditScoreComponent(creditScore);
                    return result == 10 || result == 20 || result == 35 || result == 50 || result == 75;
                });
        }

        [Property(MaxTest = 100)]
        public Property DtiComponent_ReturnsValidBracket()
        {
            return Prop.ForAll(
                Arb.From(Gen.Choose(0, 20000).Select(x => (decimal)x / 100m)),
                dtiRatio =>
                {
                    int result = CreditEvaluationCalculator.CalculateDtiComponent(dtiRatio);
                    return result == 0 || result == 10 || result == 20 || result == 30;
                });
        }

        [Property(MaxTest = 100)]
        public Property RiskScore_InRangeAndEqualsComponentSum()
        {
            return Prop.ForAll(
                Arb.From(Gen.Choose(300, 850)),
                Arb.From(Gen.Choose(0, 20000).Select(x => (decimal)x / 100m)),
                (creditScore, dtiRatio) =>
                {
                    int result = CreditEvaluationCalculator.CalculateRiskScore(creditScore, dtiRatio);
                    int creditComponent = CreditEvaluationCalculator.CalculateCreditScoreComponent(creditScore);
                    int dtiComponent = CreditEvaluationCalculator.CalculateDtiComponent(dtiRatio);
                    int expectedRaw = Math.Min(100, Math.Max(0, creditComponent + dtiComponent));
                    return result >= 0 && result <= 100 && result == expectedRaw;
                });
        }

        [Property(MaxTest = 100)]
        public Property Recommendation_ReturnsValidCategory()
        {
            return Prop.ForAll(
                Arb.From(Gen.Choose(0, 100)),
                Arb.From(Gen.Choose(0, 20000).Select(x => (decimal)x / 100m)),
                (riskScore, dtiRatio) =>
                {
                    string result = CreditEvaluationCalculator.DetermineRecommendation(riskScore, dtiRatio);
                    return result == "Recommended for Approval"
                        || result == "Manual Review Required"
                        || result == "High Risk - Recommend Rejection";
                });
        }
    }
}
