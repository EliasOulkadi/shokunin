---
name: legal-counsel
description: Structured legal reference for GDPR, EU AI Act, DSA/DMA, CCPA/CPRA, HIPAA (2026 updates), ADA/WCAG digital accessibility, DMCA, US state privacy laws (15+ states), and contract review. Use when user asks about GDPR compliance, privacy law, cookie consent, data protection, AI regulation, HIPAA, ADA, DMCA, contract clauses, or multi-state US privacy laws. Do NOT use for jurisdiction-specific litigation strategy, employment disputes, criminal law, or immigration. Always verify against official legal texts.
license: MIT
compatibility: opencode
metadata:
  workflow: legal
  audience: developers
  version: "2.0"
---

**IMPORTANT DISCLAIMER**: Reference information for educational and preliminary analysis. NOT legal advice. No attorney-client relationship. Laws vary by jurisdiction and change frequently. Always consult a qualified attorney.

## Core Analysis Framework

| Lens | What it asks |
|------|-------------|
| Jurisdiction | Which law applies? (EU, UK, US federal, US state) |
| Obligation | What must you do? (mandatory vs recommended) |
| Risk | What happens if you don't? (fines, lawsuits, reputation) |
| Timeline | When must you comply? (deadlines, phased enforcement) |

## EU Law

### GDPR (Regulation EU 2016/679)
**Applies to**: Any organization processing personal data of EU residents.
**Lawful basis** (6): Consent, contract, legal obligation, vital interest, public task, legitimate interest.
**Consent**: Specific, informed, unambiguous, freely given, revocable. No pre-ticked boxes.
**DSAR**: 30 days. Mostly free. Can extend 60 days for complex.
**Breach notification**: 72 hours to authority. Notify subjects if high risk.
**DPIA**: Required for high-risk processing (profiling, large-scale sensitive data).
**Fines**: Up to 4% of annual global turnover or EUR 20M.

### DSA (Digital Services Act)
**Applies to**: Platforms, marketplaces, social media reaching EU users.
**Key requirements**:
- Notice-and-action for illegal content
- Transparency reporting (quarterly for VLOPs)
- User redress (internal complaint system + out-of-court dispute)
- Risk assessments for VLOPs (Very Large Online Platforms)
- Recommendation system transparency

### DMA (Digital Markets Act)
**Applies to**: Gatekeepers (platforms with >45M EU users, >75B EUR market cap).
**Requirements**: Interoperability, data portability, no self-preferencing, no anti-steering.

### EU AI Act (Regulation 2024/1689)

| Tier | Examples | Requirements |
|------|----------|-------------|
| Minimal | Chatbots, spam filters | Transparency: label AI |
| Limited | AI customer support | User must know it's AI |
| High-risk | CV screening, credit scoring, medical AI | Conformity assessment, risk mgmt, human oversight |
| Unacceptable | Social scoring, predictive policing | Prohibited entirely |

**Fines**: Up to 7% of annual global turnover for prohibited practices.
**Enforcement timeline**: Phased 2025-2027. Codes of Practice expected mid-2026.

### ePrivacy Directive (Cookie Law)
- Strict opt-in for non-essential cookies
- No cookie walls (blocking unless user accepts all)
- Granular: necessary, preferences, statistics, marketing
- Consent stored with proof

## US Law

### DMCA (17 U.S.C. § 512)
- Safe harbor for OSPs with notice-and-takedown
- Repeat infringer policy required
- DMCA registered agent (Copyright Office)
- Counter-notice: content restored in 10-14 business days

### HIPAA (2026 Security Rule Updates)
- Encryption of all ePHI at rest and in transit (mandatory, no longer "addressable")
- MFA required for all ePHI access
- 72-hour breach notification (reduced from 60 days)
- Annual penetration testing
- Fines: $100-$50,000 per violation, up to $1.5M per year per category

### ADA / WCAG Digital Accessibility
- 2026: DOJ adopted WCAG 2.1 Level AA for public entities (Title II)
- Deadlines: April 24, 2026 (populations 50K+), April 26, 2027 (under 50K)
- POUR: Perceivable, Operable, Understandable, Robust
- Private sector: No specific rule but 5,000+ ADA website lawsuits in 2025

### State Privacy Laws (15+)

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

### Contract Review Framework

| Clause | Red Flag |
|--------|----------|
| Indemnification | Unlimited IP indemnity; no reciprocal |
| Limitation of liability | No cap; cap < contract value |
| Data processing | No DPA/BAA; no sub-processor approval |
| Termination | Auto-renewal without notice; no data export |
| IP ownership | Assignment of improvements |
| SLA | 99% or below; credits as sole remedy |
| Governing law | Non-mutual venue; inconvenient forum |

## Web Compliance Checklist

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
