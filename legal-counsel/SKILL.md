---
name: legal-counsel
description: Legal analysis for EU and US law
---

## Core Analysis Framework

| Lens | What it asks | Why it matters |
|------|-------------|----------------|
| **Jurisdiction** | Which law applies? | EU, UK, and US have fundamentally different approaches. US varies by state. |
| **Obligation** | What must you do? | Mandatory vs recommended vs optional. Non-negotiable vs negotiable. |
| **Risk** | What happens if you don't? | Fines, lawsuits, reputation damage, or nothing. Risk tier determines priority. |
| **Timeline** | When must you comply? | Some laws have phased deadlines. Knowing the date matters as much as the rule. |

---

## EU Law

### GDPR (Regulation EU 2016/679)

**Applies to**: Any organization processing personal data of EU residents, regardless of location.

**Lawful bases for processing** (6):
Consent, contract, legal obligation, vital interest, public task, legitimate interest. You must document which basis applies for each processing activity.

**Consent requirements**:
- Specific, informed, unambiguous, freely given, revocable
- Pre-ticked boxes are NOT valid consent
- Consent must be as easy to withdraw as to give

**Cookie consent**: Required BEFORE setting non-essential cookies (ePrivacy Directive). Granular per category. No cookie walls that force accept-all.

**DSAR (Data Subject Access Request)**: Fulfill within 30 days. Mostly free. Can extend by 60 days for complex requests.

**Data breach notification**: Within 72 hours to supervisory authority. If high risk to individuals, also notify the data subjects without delay.

**DPIA (Data Protection Impact Assessment)**: Required for processing that is "likely to result in high risk" (profiling, large-scale sensitive data, systematic monitoring).

**Fines**: Up to 4% of annual global turnover or EUR 20 million, whichever is higher. Tiered system: 2% for administrative violations, 4% for core violations.

**2026 updates**:
- EU Data Act (Regulation 2023/2854): IoT data sharing, cloud switching rights, interoperability requirements
- EU AI Act enforcement beginning (see below)

### UK GDPR

**Applies to**: Organizations processing data of UK residents. Post-Brexit, the UK maintains its own version of GDPR (UK GDPR) supplemented by the Data Protection Act 2018.

**Key differences from EU GDPR**:
- UK has its own supervisory authority (ICO) with separate guidance
- Adequacy decision from EU currently in place but subject to review (next review 2027)
- UK standard contractual clauses (SCCs) differ from EU SCCs
- International data transfers require separate UK mechanisms
- ICO fines follow same structure but ICO has indicated more pragmatic enforcement approach
- UK has separate ePrivacy regime (PECR â€” Privacy and Electronic Communications Regulations)

**Practical impact**: If you serve both EU and UK users, you need compliance programs for both. A single GDPR program does not automatically satisfy UK GDPR requirements.

### EU AI Act (Regulation 2024/1689)

| Tier | Examples | Requirements |
|------|----------|-------------|
| Minimal | AI chatbots, spam filters | Transparency (label as AI-generated) |
| Limited | AI customer support with disclosure | User must know they are interacting with AI |
| High-risk | CV screening, credit scoring, medical AI, recruitment | Conformity assessment, risk management, human oversight, technical documentation |
| Unacceptable | Social scoring, predictive policing, emotion recognition in workplaces | Prohibited entirely |

**Applies to**: Providers placing AI on EU market AND deployers located in the EU, regardless of where the provider is based. Extraterritorial reach similar to GDPR.

**Fines**: Up to 7% of annual global turnover for prohibited practices, 3% for other violations.

### ePrivacy Directive (Cookie Law)

- Strict opt-in consent for non-essential cookies and tracking
- No "cookie wall" that blocks access unless user accepts all
- Legitimate interest does NOT apply to cookies (clarified by EDPB guidelines)
- Cookie consent must be granular per category (necessary, preferences, statistics, marketing)
- Consent must be stored with proof (who, when, what they agreed to)

---

## US Law

### Federal Laws

#### DMCA (Digital Millennium Copyright Act) â€” 17 U.S.C. Â§ 512

- Safe harbor for Online Service Providers (OSPs) who comply with notice-and-takedown
- Takedown notice requirements: identification of copyrighted work, identification of infringing material, contact info, good faith belief of infringement, statement of accuracy under penalty of perjury, physical or electronic signature
- Counter-notice: user can dispute; content restored in 10-14 business days unless lawsuit filed
- Repeat infringer policy required for safe harbor protection
- DMCA registered agent required (Copyright Office)
- Failure to comply can result in loss of safe harbor and direct liability for copyright infringement

#### HIPAA (Health Insurance Portability and Accountability Act)

**Applies to**: Covered entities (healthcare providers, health plans, clearinghouses) and Business Associates (SaaS vendors handling PHI).

**2026 Security Rule updates** (proposed December 2025):
- Encryption of all ePHI at rest and in transit â€” no longer "addressable", now mandatory
- Multi-factor authentication (MFA) required for all ePHI access
- 72-hour breach notification to HHS (reduced from 60 days)
- Annual penetration testing and vulnerability scanning every 6 months
- Enhanced documentation and written verification from business associates
- Source: Medcurity, HHS proposed rule December 2025

**Business Associate Agreement (BAA)** requirements:
- Written contract describing permitted uses of PHI
- Prohibition on further disclosure
- Safeguards implementation
- Breach reporting to covered entity
- Subcontractor requirements (flow-down provisions)
- Source: HHS OCR guidance, Konfirmity 2026

**Fines**: Tiered from $100 to $50,000 per violation, up to $1.5 million per year per violation category.

#### ADA / WCAG (Americans with Disabilities Act â€” Digital Accessibility)

**2026 update**: DOJ final rule (April 2024) adopted WCAG 2.1 Level AA as the technical standard for digital accessibility under Title II of the ADA. This is the first time the DOJ has adopted a specific technical standard for digital content.

**Compliance deadlines**:
- April 24, 2026: Public entities with population 50,000+
- April 26, 2027: Public entities under 50,000 and special districts

**WCAG 2.1 AA key requirements (POUR)**:
- Perceivable: alt text on images, captions on video, high contrast (4.5:1 minimum)
- Operable: full keyboard navigation, no keyboard traps, sufficient time, no seizures
- Understandable: readable text, predictable behavior, input assistance
- Robust: compatible with assistive technologies (screen readers)

**Private sector**: While Title III (public accommodations) has not adopted specific WCAG rules, courts increasingly interpret the ADA to require accessible websites. Over 5,000 ADA website lawsuits filed in 2025 (source: UsableNet). E-commerce accounts for nearly 70%.

#### SOX (Sarbanes-Oxley Act)

**Applies to**: Publicly traded companies in the US and their auditors.

**Key provisions for SaaS**:
- Section 404: Internal controls over financial reporting (ICFR) â€” documented, tested, audited
- Section 302: CEO/CFO certification of financial statements
- Record retention: 5-7 years for audit records
- IT controls (COBIT, COSO frameworks commonly used)
- Access controls, change management, backup and recovery all subject to auditor review

### State Privacy Laws

As of 2026, 15+ states have comprehensive privacy laws. The landscape is complex and requirements vary.

| State | Law | Effective | Thresholds | Key differences |
|-------|-----|-----------|------------|-----------------|
| California | CCPA/CPRA | 2020/2023 | $25M revenue OR 100K consumers OR 50% revenue from data sales | Broadest law. Private right of action (data breaches). CPPA enforcement active. |
| Virginia | VCDPA | 2023 | 100K consumers OR 25K + 50% revenue from data sales | No private right of action. AG enforcement only. |
| Colorado | CPA | 2023 | 100K consumers OR 25K + data sales revenue | Must honor GPC signals. Universal opt-out required. |
| Connecticut | CTDPA | 2023 | 100K consumers OR 25K + 25% revenue from data sales | 25% threshold (lower than others). |
| Utah | UCPA | 2023 | $25M revenue + 100K consumers OR 25K + 50% revenue | Revenue threshold unlike VA/CO/CT. |
| Iowa | ICDPA | 2025 | 100K consumers OR 25K + 50% revenue | No private right of action. |
| Indiana | INCDPA | 2026 | 100K consumers OR 25K + 50% revenue | Effective July 2026. |
| Montana | MTCDPA | 2024 | 100K consumers OR 25K + 50% revenue | Similar to Virginia model. |
| Tennessee | TCPA | 2025 | 100K consumers OR 25K + 50% revenue | AG enforcement only. |
| Texas | TDPSA | 2024 | Conducts business in TX + processes consumer data | Broad applicability. |
| Oregon | OCPA | 2024 | 100K consumers OR 25K + 25% revenue | Lower revenue threshold. |
| Delaware | DPDPA | 2025 | 75K consumers OR 25K + 20% revenue | Lower thresholds than most. 20% revenue trigger. |
| Florida | FDBR | 2024 | $1B+ revenue + specific processing thresholds | Only applies to very large companies. |
| Nebraska | NDPA | 2025 | 100K consumers OR 25K + 50% revenue | Similar to Virginia model. |
| New Hampshire | NHPA | 2026 | 100K consumers OR 25K + 50% revenue | Effective 2026. |

**Practical approach to US state privacy**:
- If you meet the strictest threshold (California's $25M revenue), you likely meet all state thresholds
- Most state laws share similar consumer rights (access, delete, correct, portability, opt-out)
- Key variations: sensitive data consent (opt-in required in VA/CO/CT, not in CA), GPC signal requirements (CO/CT require honoring), private right of action (CA only)
- Best practice: implement a single compliance program that satisfies the most stringent requirements across all applicable states

Source: Sourcepoint comparison chart, Linklaters "Data Protected US", Feroot Security state law comparison, Usercentrics US state laws guide.

---

## Web Compliance Checklist

### Privacy & Data
- [ ] Privacy policy posted, complete, and jurisdiction-specific
- [ ] Cookie consent banner with granular categories and records
- [ ] DSAR handling procedure documented and tested
- [ ] Data retention schedule published and enforced
- [ ] Data Processing Agreements (DPAs/BAAs) with all vendors
- [ ] Data mapping completed (where data lives, flows, who accesses it)

### Terms & Legal
- [ ] Terms of Service / Terms of Use posted
- [ ] Acceptable use policy defined
- [ ] Limitation of liability clause included
- [ ] DMCA takedown agent registered (US)
- [ ] Repeat infringer policy documented
- [ ] Dispute resolution / arbitration clause
- [ ] Privacy policy linked in account registration flow

### Accessibility
- [ ] Alt text on all meaningful images
- [ ] Keyboard navigation works for all interactive elements
- [ ] Color contrast meets WCAG 2.1 AA (4.5:1 ratio)
- [ ] Forms have accessible labels and error messages
- [ ] Video content has captions
- [ ] Screen reader tested (VoiceOver, NVDA, JAWS)
- [ ] `prefers-reduced-motion` respected
- [ ] Focus indicators visible on all interactive elements

### Security
- [ ] HTTPS enforced (TLS 1.2+)
- [ ] Encryption at rest (AES-256) and in transit
- [ ] MFA on all administrative access
- [ ] Incident response plan documented and tested
- [ ] Vendor security assessments completed
- [ ] Penetration testing (at least annually)
- [ ] Vulnerability scanning (at least quarterly)

---

## Contract Review Framework

| Clause | What to check | Red flag |
|--------|--------------|----------|
| **Indemnification** | Scope, caps, who covers what | Unlimited indemnification for your IP; reciprocal indemnity missing |
| **Limitation of liability** | Cap amount, exclusions | No cap; cap less than contract value; exclusions that swallow the cap |
| **Data processing** | GDPR/CCPA compliance, sub-processors, data location | No DPA/BAA; no sub-processor approval rights; unlimited data retention |
| **Termination** | Notice period, for cause/for convenience, data return | Auto-renewal without notice; no data export on termination; minimum term > 12 months |
| **IP ownership** | Who owns what, pre-existing IP, license scope | Assignment of improvements; no license to pre-existing IP |
| **SLA** | Uptime guarantee, credits, remedies | 99% or below; credits as sole remedy; no service credits for extended downtime |
| **Governing law** | Jurisdiction, venue | Non-mutual venue selection; inconvenient forum |
| **Confidentiality** | Definition, exclusions, term | No standard exclusions (public info, independently developed); perpetual term |
| **Audit rights** | Notice period, frequency, cost | Audits on no notice; unlimited frequency; audit costs on you regardless of outcome |

---

## Sources

### EU/UK Law
- GDPR: Regulation EU 2016/679 (official text)
- EU AI Act: Regulation EU 2024/1689 (official text)
- EU Data Act: Regulation EU 2023/2854 (official text)
- ePrivacy Directive: Directive 2002/58/EC as amended
- UK GDPR: Data Protection Act 2018 + UK GDPR
- ICO guidance on UK GDPR (ico.org.uk)
- EDPB guidelines on consent, DSARs, and cookie walls

### US Federal Law
- CCPA: California Civil Code Â§ 1798.100-1798.199
- CPRA/CCPA 2026 updates: CPPA regulations effective January 1, 2026
- DMCA: 17 U.S.C. Â§ 512
- HIPAA: 45 CFR Parts 160, 164 (Privacy Rule, Security Rule, Breach Notification)
- HHS proposed HIPAA Security Rule update (December 2025)
- ADA: 42 U.S.C. Â§ 12101 et seq., DOJ Title II final rule (April 2024)
- WCAG 2.1: W3C Web Content Accessibility Guidelines
- SOX: 15 U.S.C. Â§ 7201 et seq.

### US State Laws
- Sourcepoint "US State Privacy Law Comparison Chart"
- Linklaters "Data Protected US" multi-state guide
- Feroot Security "State Privacy Law Comparison" (2026)
- Usercentrics "U.S. State Privacy Laws by State"
- Keller & Heckman state privacy comparison
- Jackson Lewis "Navigating CCPA: 30+ Essential FAQs" (Jan 2026)

### Accessibility
- BBK Law "New Digital Accessibility Requirements in 2026"
- Firespring "2026 ADA Website Compliance Guide"
- AccessiBe "ADA Compliance Checklist 2026"
- TransPerfect "ADA Update 2026: What Businesses Need to Know"
- UsableNet "ADA Web Lawsuit Trends 2025-2026"

### HIPAA
- Medcurity "HIPAA Security Rule Changes in 2026"
- Konfirmity "HIPAA For SaaS" (2026)
- Accountable "HIPAA Compliance for SaaS Companies" (2026)
- HHS OCR: HIPAA Security Rule guidance

### General
- American Bar Association model contract clauses
- Uniform Commercial Code (UCC) Article 2
- EU adequacy decision for UK (review 2027)






