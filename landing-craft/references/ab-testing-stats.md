# A/B Testing Statistics Guide

## Table of Contents

- [Key Concepts](#key-concepts)
- [Sample Size Calculator](#sample-size-calculator)
- [Bayesian vs Frequentist](#bayesian-vs-frequentist)
- [Minimum Detectable Effect](#minimum-detectable-effect)
- [Statistical Significance (95%)](#statistical-significance-95)
- [Sequential Testing (Always-Valid p-Values)](#sequential-testing-always-valid-p-values)
- [The Peeking Problem](#the-peeking-problem)
- [Setting Up Proper Experiments](#setting-up-proper-experiments)
- [Common Mistakes Checklist](#common-mistakes-checklist)

---

## Key Concepts

| Concept | Definition | Why it matters |
|---------|-----------|----------------|
| **Null hypothesis (H₀)** | The treatment has no effect | We assume this until data proves otherwise |
| **Alternative hypothesis (H₁)** | The treatment has an effect | What we're trying to prove |
| **p-value** | Probability of observing this result (or more extreme) if H₀ is true | p < 0.05 means we reject H₀ |
| **Statistical significance** | Confidence that the result isn't random noise | Standard: 95% confidence (p < 0.05) |
| **Statistical power** | Probability of detecting a true effect (if it exists) | Target: 80% power |
| **Type I error (α)** | False positive — saying there's an effect when there isn't | Risk set to 5% by convention |
| **Type II error (β)** | False negative — saying there's no effect when there is | Risk set to 20% by convention |
| **MDE (Minimum Detectable Effect)** | Smallest effect you can reliably detect given sample size | Smaller effects need more visitors |
| **Multiple comparison problem** | Running many tests inflates false positive rate | Each extra comparison increases α |

---

## Sample Size Calculator

### The Formula (Frequentist)

For a two-tailed test comparing two proportions:

```
n = (Z_α/2 + Z_β)² × [p₁(1-p₁) + p₂(1-p₂)] / (p₂ - p₁)²
```

Where:
- Z_α/2 = 1.96 (for α = 0.05, two-tailed)
- Z_β = 0.84 (for β = 0.20, power = 80%)
- p₁ = baseline conversion rate
- p₂ = expected conversion rate with treatment

### Quick Reference Table

Required visitors **per variant** for 80% power at 95% significance:

| Baseline | MDE 5%  | MDE 10% | MDE 20% | MDE 50% |
|----------|---------|---------|---------|---------|
| 1%       | 200,000 | 48,000  | 12,000  | 1,900   |
| 2%       | 98,000  | 24,500  | 6,100   | 970     |
| 5%       | 41,000  | 10,000  | 2,500   | 400     |
| 10%      | 22,000  | 5,500   | 1,350   | 220     |
| 20%      | 12,500  | 3,100   | 750     | 125     |
| 50%      | 10,500  | 2,600   | 640     | 100     |

### JavaScript Calculator

```javascript
function requiredSampleSize(baselineRate, mde, alpha = 0.05, power = 0.8) {
  const zAlpha = alpha === 0.05 ? 1.96 : alpha === 0.01 ? 2.576 : null
  const zBeta = power === 0.8 ? 0.8416 : power === 0.9 ? 1.2816 : null

  if (!zAlpha || !zBeta) throw new Error('Unsupported alpha/power combination')

  const p1 = baselineRate
  const p2 = baselineRate * (1 + mde)
  const pooled = (p1 * (1 - p1) + p2 * (1 - p2)) / 2
  const se = Math.sqrt(2 * pooled)
  const delta = p2 - p1

  return Math.ceil(Math.pow((zAlpha + zBeta) * se / delta, 2))
}

// Usage
console.log(requiredSampleSize(0.05, 0.1))
// 5% baseline, 10% relative MDE → ~10,000 per variant
```

### Rules of Thumb

- **Low traffic (< 500 visitors/week)**: Test only large changes (MDE > 30%) or use qualitative methods
- **Medium traffic (500-5,000/week)**: Can detect moderate effects (15-30% MDE)
- **High traffic (5,000+/week)**: Can run frequent tests with reasonable sample sizes
- **SAAS landing pages**: Expect 2-5% conversion. 10% MDE → ~10,000 visitors per variant

### When You Can't Reach Minimum Sample Size

1. **Sequential testing** (see below) — requires fewer visitors in practice
2. **Bayesian methods** — more sample-efficient with informative priors
3. **Switch to qualitative**: User testing, surveys, heatmaps, session recordings
4. **Increase traffic**: Run campaigns to the test page
5. **Test high-traffic pages only**: Don't waste tests on low-traffic pages

---

## Bayesian vs Frequentist

| Aspect | Frequentist | Bayesian |
|--------|-------------|----------|
| **Core question** | "How likely is this data given H₀ is true?" | "How likely is H₁ given this data?" |
| **Prior beliefs** | Not considered | Explicitly incorporated |
| **Interpretation** | p-value = P(data or more extreme \| H₀) | Posterior = P(H₁ \| data) |
| **Can stop early?** | No (peeking problem) | Yes (with proper stopping rules) |
| **Intuitiveness** | Counterintuitive for non-statisticians | Maps to how humans naturally reason |
| **Computational cost** | Simple formulas | MCMC or closed-form conjugate priors |
| **Multiple testing** | Correction required (Bonferroni, Benjamini-Hochberg) | Naturally handles via shrinkage |
| **Sample efficiency** | Needs full sample | Can (theoretically) use less with strong priors |

### Which One Should You Use?

**Use Frequentist when:**
- You need regulatory/audit-friendly analysis
- Running simple A/B tests with clear stopping rules
- You have a dedicated data science team

**Use Bayesian when:**
- You want probabilistic interpretations ("87% chance B is better")
- Running many concurrent tests
- You want to stop tests early with confidence
- Communicating results to non-technical stakeholders
- You have prior data from similar experiments

### Practical Recommendation

For most landing page A/B tests:

1. **Design the experiment using frequentist formulas** (sample size, power)
2. **Run with sequential testing** (always-valid p-values) to allow early stopping
3. **Report Bayesian posteriors** to stakeholders: "B has a 92% chance of beating A with a mean lift of 14% ± 5%"

### Bayesian Calculator (Beta-Binomial Conjugate)

```javascript
function posteriorBeta(controlA, controlB, variantA, variantB) {
  // Prior: Beta(1, 1) — uniform, uninformative
  const priorAlpha = 1
  const priorBeta = 1

  return {
    control: {
      alpha: controlA + priorAlpha,
      beta: controlB + priorBeta,
      mean: () => (controlA + priorAlpha) / (controlA + controlB + priorAlpha + priorBeta),
    },
    variant: {
      alpha: variantA + priorAlpha,
      beta: variantB + priorBeta,
      mean: () => (variantA + priorAlpha) / (variantA + variantB + priorAlpha + priorBeta),
    },
    probabilityBBeatsA: () => {
      // Monte Carlo approximation
      const samples = 100000
      let bWins = 0
      for (let i = 0; i < samples; i++) {
        const c = sampleBeta(controlA + priorAlpha, controlB + priorBeta)
        const v = sampleBeta(variantA + priorAlpha, variantB + priorBeta)
        if (v > c) bWins++
      }
      return bWins / samples
    }
  }
}

function sampleBeta(alpha, beta) {
  const x = Math.random()
  const y = Math.random()
  const gamma1 = -Math.log(1 - Math.pow(x, 1/alpha))
  const gamma2 = -Math.log(1 - Math.pow(y, 1/beta))
  return gamma1 / (gamma1 + gamma2)
  // Proper implementation: use Marsaglia & Tsang method
}
```

---

## Minimum Detectable Effect (MDE)

The smallest relative change you can detect with your sample size.

### MDE Formula (reverse from sample size)

```
MDE = (Z_α/2 + Z_β) × √(2 × p × (1-p) / n)
```

Where p = baseline conversion rate, n = visitors per variant.

### Practical MDE Guide

| Business context | Realistic MDE | Strategy |
|-----------------|--------------|----------|
| E-commerce checkout changes | 2-5% | Small wins compound; high traffic needed |
| Landing page headline | 10-30% | Big swings; worth testing on moderate traffic |
| Pricing page restructuring | 5-15% | Potentially high impact, medium traffic needed |
| Button color change | 1-3% | Negligible alone; test only if very high traffic |
| Form field reduction | 10-25% | Established pattern; worth testing |
| Adding social proof | 8-15% | Well-documented; likely to work |

### Setting MDE for Your Test

1. **Don't use the MDE that the sample size calculator spits out** based on your traffic (that's backward)
2. Instead: decide what effect is **worth implementing** (time cost of change × impact)
3. Then calculate if you can detect it

**Example:**
- Changing a headline takes 1 hour
- A 5% lift on $100,000/month revenue = $5,000/month
- Worth implementing? Yes
- Can we detect 5%? If baseline is 5% and traffic is 50,000/month, yes. If 500/month, no.

### MDE by Traffic

| Daily visitors | Test duration | MDE (baseline 5%, 80% power) |
|---------------|---------------|------------------------------|
| 100 | 2-3 weeks | ~30% |
| 500 | 1 week | ~15% |
| 2,000 | 1 week | ~7% |
| 10,000 | 3 days | ~3% |
| 50,000 | 1 day | ~1.5% |

---

## Statistical Significance at 95%

### What It Actually Means

**Correct:** If there is truly no difference (H₀ is true), and we ran this experiment many times, we'd falsely declare significance in only 5% of runs.

**Incorrect:** "There's a 95% chance the treatment is better." (That's the Bayesian interpretation.)

### Why You Shouldn't Stop at p < 0.05

- **P-hacking**: Run 20 tests, one will be significant by chance
- **Low power**: p < 0.05 with small sample → effect is probably overestimated
- **Baseline volatility**: Short tests may capture anomalous periods

### What to Check Before Declaring a Winner

| Check | Why | How |
|-------|-----|-----|
| Minimum sample reached | Underpowered tests overestimate effects | Use sample size calculator |
| Minimum runtime | Captures weekly cycles | At least 7 full days |
| Both weekday/weekend | User behavior differs | 7+ days minimum |
| Segments consistent | Effect shouldn't reverse in subgroups | Check new vs returning, device, source |
| No peeking | Early stopping inflates false positives | Sequential testing or fixed horizon |
| p-value stable | Drifting p-value = unreliable result | Plot p-value over time |
| Sensible magnitude | Unrealistically large effect? | 50%+ lifts are rare |
| Confidence interval | Tells you the plausible range | Report: "Lift: 12% ± 4% (95% CI)" |

### Confidence Intervals Over p-Values

Always report confidence intervals alongside p-values:

```
Variant B conversion: 6.2% (95% CI: 5.8% - 6.6%)
Control conversion:   5.4% (95% CI: 5.0% - 5.8%)
Relative lift:        14.8% (95% CI: 8% - 22%)
p-value:              0.003
```

A confidence interval tells you:
- The **range** of plausible effect sizes (not just "significant or not")
- Whether the effect is **practically significant** (CI doesn't include 0 AND the minimum effect worth implementing)
- The **precision** of your estimate (wider = less data)

---

## Sequential Testing (Always-Valid p-Values)

### The Problem with Fixed-Horizon Testing

Traditional A/B testing requires a fixed sample size calculated in advance. If you stop the test early when results look good, your false positive rate skyrockets.

### The Peeking Problem in Numbers

| Peeking frequency | Effective false positive rate |
|------------------|------------------------------|
| 1 look (end only) | 5% (nominal) |
| 5 looks | ~14% |
| 10 looks | ~19% |
| Continuous peeking | ~25-30% |

### Always-Valid p-Values (Mixture Sequential Probability Ratio Test)

Uses the mSPRT (Mixture Sequential Probability Ratio Test) — allows you to check results at any time without inflating false positives.

**Implementation approach:**

```javascript
// Simplified always-valid p-value using the mSPRT
// Based on Johari et al. (2017) "Always Valid Inference"

function alwaysValidPValue(treatmentConversions, treatmentVisitors,
                           controlConversions, controlVisitors,
                           alpha = 0.05) {
  // This is a simplified approximation
  // For production: use a proper mSPRT implementation
  // Reference: https://github.com/ron-ald/always-valid-p-values

  const tRate = treatmentConversions / treatmentVisitors
  const cRate = controlConversions / controlVisitors
  const delta = tRate - cRate

  // Variance under null
  const pooledRate = (treatmentConversions + controlConversions) /
                     (treatmentVisitors + controlVisitors)
  const se = Math.sqrt(pooledRate * (1 - pooledRate) *
              (1/treatmentVisitors + 1/controlVisitors))

  // Z-statistic
  const z = delta / se

  // Adjusted boundary (always-valid)
  // The adjustment factor ~ sqrt(2 * log(log(n)))
  const n = treatmentVisitors + controlVisitors
  const adjustment = Math.sqrt(2 * Math.log(Math.log(Math.max(n, 100))))
  const adjustedZ = z / adjustment

  // Two-tailed p-value
  const p = 2 * (1 - normalCDF(Math.abs(z)))
  const adjustedP = 2 * (1 - normalCDF(Math.abs(adjustedZ)))

  return { p, adjustedP, canReject: adjustedP < alpha }
}

function normalCDF(x) {
  // Approximation of standard normal CDF
  const a1 =  0.254829592
  const a2 = -0.284496736
  const a3 =  1.421413741
  const a4 = -1.453152027
  const a5 =  1.061405429
  const p  =  0.3275911
  const sign = x < 0 ? -1 : 1
  x = Math.abs(x) / Math.sqrt(2)
  const t = 1 / (1 + p * x)
  const y = 1 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x)
  return 0.5 * (1 + sign * y)
}
```

### Practical Sequential Testing Strategy

| Traffic level | Method | Tools |
|--------------|--------|-------|
| Low (<500/wk) | Fixed-horizon with mSPRT guard | Manual calc, Evan Miller |
| Medium | Sequential with group sequential design | Optimizely, VWO |
| High | Continuous monitoring with always-valid p-values | Google Optimize, custom |

### Sample Size Multiplier for Sequential Testing

Sequential tests need more samples than fixed-horizon:

| Number of planned looks | Sample size multiplier |
|------------------------|----------------------|
| 2 | 1.1x |
| 5 | 1.2x |
| 10 | 1.3x |
| Unlimited (continuous) | 1.5-2x |

---

## The Peeking Problem

### What Happens When You Peek

```
Day 1: p = 0.45 → "Not significant yet"
Day 2: p = 0.38 → "Getting closer"
Day 3: p = 0.22 → "Almost there..."
Day 4: p = 0.04 → "Significant! Ship it!" ← MAY BE FALSE POSITIVE
Day 5: p = 0.08 → "Hmm, regressed"
```

### Why This Happens

Random fluctuations will occasionally push p below 0.05 even when there's no real effect. By checking daily, you're running multiple tests on the same data.

**The correction:** If you check 10 times, your actual false positive rate is ~19% (not 5%).

### How to Avoid the Peeking Problem

| Method | How it works | Trade-off |
|--------|-------------|-----------|
| **Pre-register sample size** | Calculate n in advance, don't look until n is reached | Cannot capitalize on unexpectedly large effects |
| **Sequential testing** | Use always-valid p-values | Slightly larger sample needed |
| **Holdout group** | Keep 5-10% on control after "winning" test | Delays full rollout |
| **A/A tests** | Test two identical variants to calibrate false positive rate | Extra traffic needed |
| **Blind analysis** | Automate analysis, hide results until end | Requires automated pipeline |

### The Holdout Group Approach

```
1. Run test, achieve significance
2. Roll out to 90% of traffic
3. Keep 10% on original
4. Monitor holdout for 1-2 weeks
5. If holdout confirms lift, full rollout
6. If holdout shows no lift, revert
```

**This is the most practical safeguard for most teams.**

---

## Setting Up Proper Experiments

### Pre-Test Checklist

- [ ] Hypothesis documented (ICE scored)
- [ ] Primary metric defined (conversion rate, revenue, etc.)
- [ ] Secondary metrics defined (engagement, bounce, downstream actions)
- [ ] Sample size calculated before test starts
- [ ] Runtime calculated (minimum 7 days)
- [ ] A/A test run to validate instrumentation (if new tool)
- [ ] No other tests running on the same page/element
- [ ] Audience defined (new vs returning, device, source)
- [ ] Traffic split verified (50/50 or other)
- [ ] Tool tracking verified (test conversions fire correctly)

### Randomization Rules

1. **User-level randomization** (not session-level): prevents contamination
2. **Stable assignment**: same user always sees same variant
3. **No overlapping tests on same element**: use full factorial design if needed
4. **Hash-based assignment**: use user ID hash, not random number generator

### Test Design Template

```
Experiment Name: ________________________________
Date Started: ___________________________________
Hypothesis ID: __________________________________

Control: Current landing page (no changes)
Variant: [describe specific change]

Primary metric: Conversion rate (click to sign-up)
Secondary metrics: Time on page, scroll depth, bounce rate
Segments: New vs returning, mobile vs desktop

Sample size needed: _______ per variant (____ visitors/day × ____ days)
Runtime: Start ________ → End ________

Stopping rule:
□ Fixed horizon (n = _______ visitors per variant)
□ Sequential (always-valid p < 0.05, min n = _______)

Expected MDE: _____%
Significance level: α = 0.05
Statistical power: 80%

Go/no-go criteria:
□ Significant p-value (< 0.05)
□ Minimum sample reached
□ Minimum runtime (7 days)
□ No instrumentation errors
□ Holdout validation (if applicable)
```

### Post-Test Analysis

```python
# Python implementation of A/B test analysis
import math
from scipy import stats

def analyze_ab_test(control_conversions, control_visitors,
                    variant_conversions, variant_visitors,
                    alpha=0.05):
    c_rate = control_conversions / control_visitors
    v_rate = variant_conversions / variant_visitors

    # Pooled standard error
    pooled_rate = (control_conversions + variant_conversions) / \
                  (control_visitors + variant_visitors)
    se = math.sqrt(pooled_rate * (1 - pooled_rate) *
                   (1/control_visitors + 1/variant_visitors))

    # Z-test
    z = (v_rate - c_rate) / se
    p_value = 2 * (1 - stats.norm.cdf(abs(z)))

    # Confidence interval
    z_crit = stats.norm.ppf(1 - alpha/2)
    ci_lower = (v_rate - c_rate) - z_crit * se
    ci_upper = (v_rate - c_rate) + z_crit * se

    # Relative lift
    if c_rate > 0:
        relative_lift = (v_rate - c_rate) / c_rate * 100
    else:
        relative_lift = 0

    return {
        'control_rate': c_rate,
        'variant_rate': v_rate,
        'absolute_difference': v_rate - c_rate,
        'relative_lift_pct': relative_lift,
        'p_value': p_value,
        'significant': p_value < alpha,
        'ci_95': (ci_lower, ci_upper),
        'z_statistic': z,
        'sample_size': control_visitors + variant_visitors,
    }
```

---

## Common Mistakes Checklist

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| Testing multiple elements at once | You don't know what caused the effect | One change per test |
| Stopping at a "trend" before significance | High false positive rate | Wait for significance + sample size |
| Running tests for < 7 days | Misses weekly cycles | Always run 7+ days |
| Running multiple tests on same page | Interactions between tests invalidate results | Sequences tests, run concurrently in separate page areas |
| Not tracking secondary metrics | Primary metric up but revenue down | Always check secondary metrics |
| Reporting p-values without confidence intervals | Hides effect size uncertainty | Always report CI |
| Testing what data already tells you | Waste of time | Fix obvious issues first, then test |
| Over-segmenting results ("the iOS users from Germany converted!") | Multiple comparisons problem | Pre-register segments, correct for multiple tests |
| Rolling out immediately after significance | Risk of false positive | Use holdout group or replicating test |
| Ignoring novelty effect | Users engage more with anything new | Run tests long enough (2+ weeks for UX changes) |
| Using conversion rate with very low base (<0.1%) | Takes forever to reach significance | Focus on upstream metrics (click-through, engagement) |
| Not testing the null | May have a regression in other metrics | Monitor all business metrics |

---

## References

- Johari et al. (2017) — "Always Valid Inference: Bringing Sequential Testing to A/B Testing"
- Kohavi, Tang, Xu (2020) — "Trustworthy Online Controlled Experiments: A Practical Guide to A/B Testing"
- Evan Miller — Sample Size Calculator & A/B testing tools (evanmiller.org)
- CXL Institute — Statistical Significance in A/B Testing minidegree
- Kruschke (2014) — "Doing Bayesian Data Analysis"
- Gelman et al. (2013) — "Bayesian Data Analysis" (3rd ed.)
