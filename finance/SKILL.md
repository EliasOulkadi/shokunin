---
name: finance
description: Personal finance management — budgeting, net worth tracking, debt payoff, investment allocation, tax optimization, insurance review, retirement planning, and document organization. Covers 50/30/20, zero-based, and envelope budgeting methods; avalanche vs snowball debt strategies; 3-fund portfolio allocation; tax-advantaged account prioritization; emergency fund sizing; and financial document retention schedules. Use when user asks to create a budget, track spending, plan debt payoff, review investments, optimize taxes, organize financial documents, set savings goals, or get a financial plan. Triggers on "budget", "finance", "personal finance", "money", "debt", "investing", "retirement", "savings", "net worth", "tax", "financial plan", "spending", "expenses", "income", "financial goals". Do NOT use for stock trading advice, cryptocurrency speculation, options trading, or day trading strategies — this skill covers personal financial planning, not active trading.
license: MIT
compatibility: opencode
metadata:
  workflow: finance
  audience: personal
---

**Disclaimer**: This skill provides educational financial planning information. It does not constitute professional financial advice. Consult a certified financial planner (CFP) or tax professional for your specific situation.

## Core Framework: 5 Pillars

```
Pillar 1: Cash Flow     → Income - Expenses = Surplus
Pillar 2: Net Worth     → Assets - Liabilities = Net Worth
Pillar 3: Debt          → Avalanche or Snowball
Pillar 4: Emergency     → 3-6 months of essential expenses
Pillar 5: Invest        → Tax-advantaged accounts first
```

## Pillar 1: Budgeting & Cash Flow

### Step 1: Calculate real income

Take-home pay after taxes, health insurance, retirement contributions. If variable, average last 3 months.

### Step 2: Track expenses

Categorize into:
```
Needs (50%):     Housing, utilities, groceries, insurance, minimum debt payments, transport
Wants (30%):     Dining out, entertainment, subscriptions, travel, shopping
Savings (20%):   Emergency fund, retirement, investments, extra debt payments
```

### Budgeting methods

| Method | Best for | How it works |
|--------|----------|-------------|
| 50/30/20 | Beginners | Fixed percentages for needs/wants/savings |
| Zero-based | Detail-oriented | Every dollar assigned a job. Income - expenses = 0 |
| Envelope | Overspenders | Cash for each category. When envelope is empty, stop spending |
| Pay-yourself-first | Savers | Automate savings on payday, spend what's left |

### Step 3: Find the surplus

```
Surplus = Take-home income - Fixed expenses - Variable spending - Savings goals
```

If negative: reduce variable spending, restructure goals, or increase income.

## Pillar 2: Net Worth

```
Net Worth = (Cash + Investments + Home equity + Retirement + Other assets)
            - (Mortgage + Loans + Credit cards + Other debts)
```

Track monthly. Direction matters more than the number.

## Pillar 3: Debt Payoff

| Strategy | How | Best for |
|----------|-----|----------|
| **Avalanche** | Pay minimum on all, extra to highest interest rate | Mathematically optimal |
| **Snowball** | Pay minimum on all, extra to smallest balance | Psychological wins |

Debt is an emergency if total > 6 months of income or interest rate > 10%.

## Pillar 4: Emergency Fund

```
Phase 1: $1,000 or 1 month of essential expenses (starter)
Phase 2: 3-6 months of essential expenses (full)
Phase 3: 6-12 months (conservative, for irregular income)
```

Keep in high-yield savings account (HYSA). Not invested.

## Pillar 5: Investment & Retirement

### Account priority order

```
1. 401(k) up to employer match         → Free money, do this first
2. HSA (if eligible)                   → Triple tax-advantaged
3. IRA (Roth or Traditional)           → $7,000/year ($8,000 if 50+)
4. 401(k) up to max ($23,500)          → Tax-deferred growth
5. Taxable brokerage                   → No limits, less tax-advantaged
```

### Asset allocation by age

```
3-fund portfolio:
- US total market (VTI / FSKAX):    60-70%
- International total market (VXUS): 20-30%
- US bonds (BND / FXNAX):           10-20% (age - 20 = bond %)

Target: 0.03-0.07% expense ratio. Rebalance annually.
```

### Savings targets by age (Fidelity benchmarks)

| Age | 30 | 35 | 40 | 45 | 50 | 55 | 60 | 65 |
|-----|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| 1x salary | 2x | 3x | 4x | 5x | 6x | 7x | 8x | 10x |

### Withdrawal rules

- 4% rule in traditional retirement (25x annual expenses)
- 3-3.5% for early retirement / longer horizons
- Required Minimum Distributions (RMDs) start at age 73

## Tax Optimization

### Quick wins

| Strategy | Impact |
|----------|--------|
| Max HSA ($4,150 individual / $8,300 family) | Triple tax-free (pre-tax in, tax-free growth, tax-free withdrawals for medical) |
| Max Traditional IRA for deduction phase | Reduces AGI |
| Tax-loss harvesting in taxable accounts | Offset capital gains up to $3,000/year ordinary income |
| Mega backdoor Roth (if 401(k) allows) | After-tax contributions → Roth, up to $69,000 total |
| Health insurance premiums (self-employed) | Deduct above-the-line |

### Filing status check

```
Standard deduction 2026 (estimates):
- Single:           ~$15,000
- Married filing jointly: ~$30,000
- Head of household: ~$22,500
```

Itemize only if deductions exceed standard.

## Insurance Check

| Type | What to check |
|------|-------------|
| **Health** | Deductible, out-of-pocket max, in-network coverage, HSA eligibility |
| **Auto/Home** | Liability limits ≥ $300K, umbrella policy if net worth > $500K |
| **Life** | Term only (never whole/universal). 10-12x annual income. 20-30 year term |
| **Disability** | Own-occupation. Covers 60% of income. Essential for single-income households |

## Financial Document Retention

| Document | Keep | Why |
|----------|------|-----|
| Tax returns + supporting docs | 7 years | IRS audit window (3 years general, 6 for substantial omission) |
| W-2s | Until Social Security benefits claimed | Income record for SS calculation |
| Bank/credit card statements | 1 year | Unless tax-related |
| Investment statements | Until sold | Cost basis tracking |
| Real estate closing docs | Until property sold + 7 years | Capital gains calc |
| Insurance policies | Until replaced | Coverage reference |
| Estate docs (will, trust) | Permanent | Legal reference |
| Loan documents | Until paid + 7 years | Proof of payoff |
| Receipts for warranty items | Until warranty expires | Claims |
| Pay stubs | Until reconciled with W-2 | Income verification |

## Financial Goals Framework

### SMART goals

```
I will save $X for [purpose] by [date] by [action].
→ "I will save $12,000 for emergency fund by December by automating $1,000/month from each paycheck."
```

### Priority order

1. Emergency fund (3-6 months)
2. High-interest debt (>6% APR)
3. Retirement (15% of income)
4. Mid-term goals (house, car, education)
5. Investment beyond retirement

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Budgeting every dollar without buffer | Leave 5-10% buffer for irregular expenses |
| Investing before emergency fund | 3-6 months in HYSA first |
| Whole life insurance | Term life only. Invest the difference. |
| Timing the market | Time in market beats timing the market. Dollar-cost average. |
| No tax diversification | Mix of pre-tax (401k), after-tax (Roth), and taxable |
| Ignoring asset allocation | Rebalance annually. Don't let one stock dominate. |
| Credit card debt as "normal" | Pay in full every month. If carrying balance, stop using cards. |
| No will / estate plan | Everyone needs a will, healthcare directive, and power of attorney |
