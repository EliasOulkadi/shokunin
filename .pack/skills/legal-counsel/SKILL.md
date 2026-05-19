---
name: legal-counsel
description: >-
  Structured legal reference for GDPR, EU AI Act, DSA/DMA, CCPA/CPRA, HIPAA (2026 updates),
  ADA/WCAG digital accessibility, DMCA, US state privacy laws (15+ states), and contract review.
triggers:
  - user asks about GDPR compliance, privacy law, cookie consent, data protection
  - user asks about AI regulation, EU AI Act, AI compliance
  - user asks about HIPAA, healthcare data, ePHI requirements
  - user asks about ADA, WCAG, digital accessibility
  - user asks about DMCA, copyright takedown, safe harbor
  - user asks about CCPA, CPRA, US state privacy laws
  - user asks about contract review, DPA, BAA, legal clauses
  - user asks about DSA, DMA, Digital Services Act, Digital Markets Act
negatives:
  - litigation strategy, courtroom procedure, criminal defense
  - employment law disputes, labor rights, union matters
  - immigration law, visa applications, citizenship
  - tax law, estate planning, family law, real estate transactions
  - trademark filing, patent prosecution (copyright DMCA is covered)
  - specific monetary damages calculations for a particular case
license: MIT
compatibility: opencode
metadata:
  workflow: legal
  audience: developers
  version: "3.0.0"
---


**IMPORTANT DISCLAIMER**: Reference information for educational and preliminary analysis. NOT legal advice. No attorney-client relationship. Laws vary by jurisdiction and change frequently. Always consult a qualified attorney.

## Workflow

When asked a legal compliance question, follow these steps:

| Step | Action | Notes |
|------|--------|-------|
| 1 | Identify jurisdiction(s) | EU, US federal, US state(s), UK — may overlap |
| 2 | Map the Obligation Matrix | Core Analysis Framework (below) |
| 3 | Cross-reference enforcement | Fines, private right of action, regulator trends |
| 4 | Check effective dates | Phased enforcement is common (AI Act, HIPAA 2026) |
| 5 | Return applicable code | Use sub-sections below — do not invent thresholds |
| 6 | Append disclaimer | Always close with "verify with qualified attorney" |

### Core Analysis Framework

| Lens | What it asks |
|------|-------------|
| Jurisdiction | Which law applies? (EU, UK, US federal, US state) |
| Obligation | What must you do? (mandatory vs recommended) |
| Risk | What happens if you don't? (fines, lawsuits, reputation) |
| Timeline | When must you comply? (deadlines, phased enforcement) |

## Error Handling

| Scenario | What to do | Don't do |
|----------|-----------|----------|
| User asks "is this legal?" | Frame as checklist — never a yes/no opinion | Give definitive legal judgment |
| Jurisdiction unclear | Ask which country/state the business operates in | Assume US or EU by default |
| Threshold question (revenue, user count) | Clarify exact figures before answering | Give partial guidance |
| Law recently updated | Check effective date; note "proposed/not yet in force" if applicable | Cite outdated text as current |
| User asks about pending legislation | Flag "not yet law — monitor progress" | Present as binding requirement |
| Cross-border data transfer (EU→US) | Reference DPF / SCCs / BCRs | Oversimplify transfer mechanism |

## 3. EU Law

### 3.1 GDPR (Regulation EU 2016/679)

**Applies to**: Any organization processing personal data of EU residents.
**Lawful basis** (6): Consent, contract, legal obligation, vital interest, public task, legitimate interest.
**Consent**: Specific, informed, unambiguous, freely given, revocable. No pre-ticked boxes.
**DSAR**: 30 days. Mostly free. Can extend 60 days for complex.
**Breach notification**: 72 hours to authority. Notify subjects if high risk.
**DPIA**: Required for high-risk processing (profiling, large-scale sensitive data).
**Fines**: Up to 4% of annual global turnover or EUR 20M.

### 3.2 DSA (Digital Services Act)

**Applies to**: Platforms, marketplaces, social media reaching EU users.
**Key requirements**:
- Notice-and-action for illegal content
- Transparency reporting (quarterly for VLOPs)
- User redress (internal complaint system + out-of-court dispute)
- Risk assessments for VLOPs (Very Large Online Platforms)
- Recommendation system transparency

### 3.3 DMA (Digital Markets Act)

**Applies to**: Gatekeepers (platforms >45M EU users, >75B EUR market cap).
**Requirements**: Interoperability, data portability, no self-preferencing, no anti-steering.

### 3.4 EU AI Act (Regulation 2024/1689)

| Tier | Examples | Requirements |
|------|----------|-------------|
| Minimal | Chatbots, spam filters | Transparency: label AI |
| Limited | AI customer support | User must know it's AI |
| High-risk | CV screening, credit scoring, medical AI | Conformity assessment, risk mgmt, human oversight |
| Unacceptable | Social scoring, predictive policing | Prohibited entirely |

**Fines**: Up to 7% of annual global turnover for prohibited practices.
**Enforcement timeline**: Phased 2025-2027. Codes of Practice expected mid-2026.

### 3.5 ePrivacy Directive (Cookie Law)

- Strict opt-in for non-essential cookies
- No cookie walls (blocking unless user accepts all)
- Granular: necessary, preferences, statistics, marketing
- Consent stored with proof

## 4. US Law

### 4.1 DMCA (17 U.S.C. § 512)

- Safe harbor for OSPs with notice-and-takedown
- Repeat infringer policy required
- DMCA registered agent (Copyright Office)
- Counter-notice: content restored in 10-14 business days

### 4.2 HIPAA (2026 Security Rule Updates)

- Encryption of all ePHI at rest and in transit (mandatory, no longer "addressable")
- MFA required for all ePHI access
- 72-hour breach notification (reduced from 60 days)
- Annual penetration testing
- Fines: $100-$50,000 per violation, up to $1.5M per year per category

### 4.3 ADA / WCAG Digital Accessibility

- 2026: DOJ adopted WCAG 2.1 Level AA for public entities (Title II)
- Deadlines: April 24, 2026 (populations 50K+), April 26, 2027 (under 50K)
- POUR: Perceivable, Operable, Understandable, Robust
- Private sector: No specific rule but 5,000+ ADA website lawsuits in 2025

### 4.4 State Privacy Laws (15+)

| State | Law | Effective | Revenue Threshold |
|-------|-----|-----------|-------------------|
| California | CCPA/CPRA | 2020/2023 | $25M |
| Virginia | VCDPA | 2023 | 100K consumers |
| Colorado | CPA | 2023 | 100K consumers |
| Connecticut | CTDPA | 2023 | 100K / $25M revenue |
| Utah | UCPA | 2023 | $25M + 100K |
| Iowa | ICDPA | 2025 | 100K consumers |
| Tennessee | TIPA | 2025 | 100K consumers |
| Texas | TDPSA | 2025 | $25M + data processing |
| Delaware | DDPA | 2025 | 100K consumers |

**Practical approach**: Implement one program meeting California's (most stringent) requirements. Most states share: access, delete, correct, portability, opt-out.

## 5. Contract Review Framework

| Clause | Red Flag |
|--------|----------|
| Indemnification | Unlimited IP indemnity; no reciprocal |
| Limitation of liability | No cap; cap < contract value |
| Data processing | No DPA/BAA; no sub-processor approval |
| Termination | Auto-renewal without notice; no data export |
| IP ownership | Assignment of improvements |
| SLA | 99% or below; credits as sole remedy |
| Governing law | Non-mutual venue; inconvenient forum |

## 6. Production Checklist

- [ ] Privacy policy posted, complete, jurisdiction-specific
- [ ] Cookie consent banner with granular categories
- [ ] DSAR handling procedure documented
- [ ] DPAs/BAAs with all vendors
- [ ] Data mapping completed
- [ ] DMCA takedown agent registered (US)
- [ ] Alt text on all meaningful images
- [ ] Keyboard navigation on all interactive elements
- [ ] Color contrast WCAG 2.1 AA (4.5:1)
- [ ] HTTPS enforced (TLS 1.2+)
- [ ] MFA on all administrative access
- [ ] Incident response plan tested annually
- [ ] Lawful basis documented for each processing activity
- [ ] Cross-border transfer mechanism in place (DPF/SCCs/BCRs)
- [ ] AI Act tier classification documented (if applicable)
- [ ] HIPAA BAAs with all subcontractors handling ePHI
- [ ] Breach notification procedure tested with drill
- [ ] Cookie consent records auditable (proof of consent)

## Anti-Patterns

| Anti-pattern | Why it's wrong | Instead |
|-------------|----------------|---------|
| "Just add a privacy policy" | Privacy policy alone doesn't operationalize rights (DSAR, deletion, opt-out) | Build full data-rights workflow (access → fulfill → log) |
| "GDPR doesn't apply to us — we're in the US" | GDPR applies to any org processing EU resident data, regardless of location | Always check: do you have EU users? |
| "Cookie banner = compliance" | Consent must be granular, revocable, and provable | Log consent with timestamp + scope + user ID |
| "AI Act is just about big AI" | High-risk tier covers HR, credit, medical, insurance — affects many companies | Classify your use case against Annex III before building |
| "HIPAA encryption was 'addressable' — we're fine" | 2026 update makes encryption + MFA mandatory, not addressable | Treat all addressable items as mandatory going forward |
| "We just need DMCA safe harbor" | Safe harbor requires registered agent + repeat infringer policy + prompt takedown | Complete all three requirements or safe harbor is void |
| "One privacy program fits all states" | California, Colorado, and Connecticut have material differences (opt-out, profiling, sensitive data) | Build CA-level as baseline, then diff for CO/CT unique obligations |
| "We don't process health data, HIPAA doesn't apply" | HIPAA also covers payment, treatment, operations data from covered entities — including apps that receive ePHI from providers | Sign BAA before receiving any data from covered entity |

## Sources

- GDPR: Regulation EU 2016/679
- EU AI Act: Regulation EU 2024/1689
- DSA: Regulation EU 2022/2065
- DMCA: 17 U.S.C. § 512
- HIPAA: 45 CFR Parts 160, 164
- ICO guidance (ico.org.uk)
- EDPB guidelines
- Sourcepoint "US State Privacy Law Comparison"
- DOJ Title II WCAG rule (2024)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
