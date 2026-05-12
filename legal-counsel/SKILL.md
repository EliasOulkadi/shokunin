---
name: legal-counsel
description: Provide structured legal analysis and compliance guidance for EU and US law (GDPR, AI Act, CCPA, HIPAA, ADA/WCAG, DMCA, SOX) and contract review. Use when user asks about GDPR compliance, privacy law, cookie consent, data protection, AI regulation, HIPAA requirements, ADA accessibility, DMCA takedown, contract clauses, or multi-state US privacy laws. Triggers on "is this GDPR compliant", "privacy policy", "cookie consent", "data processing agreement", "terms of service review", "accessibility requirements", "HIPAA compliance". Do NOT use for jurisdiction-specific litigation strategy, employment law disputes, criminal law, or immigration matters. Contains reference information for EU and US law — always verify against official legal texts.
license: MIT
compatibility: opencode
metadata:
  workflow: legal
  audience: developers
---

**IMPORTANT DISCLAIMER**: This skill provides structured legal reference information for educational and preliminary analysis purposes. It does NOT constitute legal advice. No attorney-client relationship is formed. Laws vary by jurisdiction, change frequently, and fact-specific analysis is required. Always consult a qualified attorney licensed in your jurisdiction for legal decisions.

## Core Analysis Framework

| Lens | What it asks | Why it matters |
|------|-------------|----------------|
| Jurisdiction | Which law applies? | EU, UK, and US have fundamentally different approaches. US varies by state. |
| Obligation | What must you do? | Mandatory vs recommended vs optional. Non-negotiable vs negotiable. |
| Risk | What happens if you don't? | Fines, lawsuits, reputation damage, or nothing. Determines priority. |
| Timeline | When must you comply? | Some laws have phased deadlines. The date matters as much as the rule. |

## EU Law

### GDPR (Regulation EU 2016/679)

**Applies to**: Any organization processing personal data of EU residents, regardless of location.

**Lawful basis for processing** (6): Consent, contract, legal obligation, vital interest, public task, legitimate interest. Must document which basis applies per processing activity.

**Consent**: Specific, informed, unambiguous, freely given, revocable. Pre-ticked boxes are NOT valid.

**DSAR**: Fulfill within 30 days. Mostly free. Can extend 60 days for complex requests.

**Breach notification**: 72 hours to supervisory authority. Notify data subjects if high risk.

**DPIA**: Required when processing is "likely to result in high risk" (profiling, large-scale sensitive data, systematic monitoring).

**Fines**: Up to 4% of annual global turnover or EUR 20M, whichever is higher.

**2026 updates**:
- EU Data Act (Regulation 2023/2854): IoT data sharing, cloud switching rights
- EU AI Act enforcement beginning (see below)

### UK GDPR

**Applies to**: Organizations processing data of UK residents.

**Key differences from EU GDPR**:
- Separate supervisory authority (ICO)
- UK-specific SCCs differ from EU SCCs
- Adequacy decision subject to 2027 review
- Separate ePrivacy regime (PECR)

**Practical impact**: Serving both EU and UK users requires compliance programs for both. One does not automatically satisfy the other.

### EU AI Act (Regulation 2024/1689)

| Tier | Examples | Key Requirements |
|------|----------|-----------------|
| Minimal | AI chatbots, spam filters | Transparency: label as AI-generated |
| Limited | AI customer support | User must know they're interacting with AI |
| High-risk | CV screening, credit scoring, medical AI | Conformity assessment, risk management, human oversight |
| Unacceptable | Social scoring, predictive policing | Prohibited entirely |

**Fines**: Up to 7% of annual global turnover for prohibited practices.

### ePrivacy Directive (Cookie Law)
- Strict opt-in for non-essential cookies
- No cookie walls (blocking access unless user accepts all)
- Legitimate interest does NOT apply to cookies
- Granular consent: necessary, preferences, statistics, marketing
- Consent must be stored with proof

## US Law

### DMCA (17 U.S.C. § 512)
- Safe harbor for OSPs complying with notice-and-takedown
- Repeat infringer policy required for safe harbor
- DMCA registered agent required (Copyright Office)
- Counter-notice: content restored in 10-14 business days unless lawsuit filed

### HIPAA
- **Applies to**: Covered entities + Business Associates
- **2026 Security Rule updates**: Encryption of all ePHI at rest and in transit (mandatory, no longer "addressable"), MFA required for all ePHI access, 72-hour breach notification (reduced from 60 days), annual pen testing
- **Fines**: $100 to $50,000 per violation, up to $1.5M per year per category

### ADA / WCAG Digital Accessibility
- **2026**: DOJ adopted WCAG 2.1 Level AA as standard (Title II)
- **Deadlines**: April 24, 2026 (populations 50K+), April 26, 2027 (under 50K)
- **POUR**: Perceivable, Operable, Understandable, Robust
- **Private sector**: No specific WCAG rule, but 5,000+ ADA website lawsuits in 2025

### SOX
- **Applies to**: Publicly traded US companies
- Section 404: Internal controls over financial reporting (ICFR)
- Section 302: CEO/CFO certification
- Access controls, change management, backup subject to auditor review

### State Privacy Laws

As of 2026, 15+ states have comprehensive privacy laws.

| State | Law | Effective | Revenue Threshold | Key Feature |
|-------|-----|-----------|-------------------|-------------|
| California | CCPA/CPRA | 2020/2023 | $25M | Broadest. Private right of action. |
| Virginia | VCDPA | 2023 | 100K consumers | No private right of action. |
| Colorado | CPA | 2023 | 100K consumers | Must honor GPC signals. |
| Connecticut | CTDPA | 2023 | 100K / $25M revenue | Lower threshold (25%). |
| Utah | UCPA | 2023 | $25M + 100K | Revenue + consumer threshold. |

**Practical approach**: Implement a single compliance program meeting the most stringent requirements (California's). Most states share similar rights: access, delete, correct, portability, opt-out.

### Contract Review Framework

| Clause | Check | Red Flag |
|--------|-------|----------|
| Indemnification | Scope, caps, reciprocity | Unlimited IP indemnity; no reciprocal indemnity |
| Limitation of liability | Cap amount, exclusions | No cap; cap < contract value |
| Data processing | GDPR/CCPA compliance, sub-processors | No DPA/BAA; no sub-processor approval |
| Termination | Notice period, data return | Auto-renewal without notice; no data export |
| IP ownership | Who owns what, pre-existing IP | Assignment of improvements |
| SLA | Uptime, credits, remedies | 99% or below; credits as sole remedy |
| Governing law | Jurisdiction, venue | Non-mutual venue; inconvenient forum |
| Audit rights | Notice period, frequency | No-notice audits; unlimited frequency |

## Web Compliance Checklist

### Privacy & Data
- [ ] Privacy policy posted, complete, jurisdiction-specific
- [ ] Cookie consent banner with granular categories
- [ ] DSAR handling procedure documented and tested
- [ ] DPAs/BAAs with all vendors
- [ ] Data mapping completed

### Terms & Legal
- [ ] Terms of Service / Terms of Use posted
- [ ] Acceptable use policy defined
- [ ] Limitation of liability clause included
- [ ] DMCA takedown agent registered (US)
- [ ] Repeat infringer policy documented

### Accessibility
- [ ] Alt text on all meaningful images
- [ ] Keyboard navigation on all interactive elements
- [ ] Color contrast meets WCAG 2.1 AA (4.5:1)
- [ ] Video content has captions
- [ ] `prefers-reduced-motion` respected
- [ ] Screen reader tested (VoiceOver, NVDA, JAWS)

### Security
- [ ] HTTPS enforced (TLS 1.2+)
- [ ] Encryption at rest (AES-256) and in transit
- [ ] MFA on all administrative access
- [ ] Incident response plan documented and tested
- [ ] Penetration testing at least annually

## Sources

### EU/UK
- GDPR: Regulation EU 2016/679
- EU AI Act: Regulation EU 2024/1689
- EU Data Act: Regulation 2023/2854
- ePrivacy Directive: 2002/58/EC
- ICO guidance: ico.org.uk
- EDPB guidelines on consent, DSARs, cookie walls

### US Federal
- CCPA/CPRA: California Civil Code § 1798.100-1798.199
- DMCA: 17 U.S.C. § 512
- HIPAA: 45 CFR Parts 160, 164
- ADA/WCAG: 42 U.S.C. § 12101, DOJ Title II rule
- SOX: 15 U.S.C. § 7201

### US State
- Sourcepoint "US State Privacy Law Comparison"
- Linklaters "Data Protected US"
- Feroot Security "State Privacy Law Comparison" (2026)
- Usercentrics "U.S. State Privacy Laws by State"
