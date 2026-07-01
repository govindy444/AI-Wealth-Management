"""Seed knowledge base — IDBI product & guidance documents.

In production this is ingested from the bank's product CMS / policy docs into the
vector store. Here it's a representative corpus so retrieval is demonstrable
offline. Each entry grounds answers about a specific product or topic.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class KnowledgeDoc:
    id: str
    title: str
    source: str
    text: str


KNOWLEDGE_DOCS: list[KnowledgeDoc] = [
    KnowledgeDoc(
        "kb_savings", "IDBI Savings Account", "IDBI Products / Savings",
        "An IDBI savings account keeps your money safe and instantly accessible while earning "
        "interest, typically around 3% per year. It is meant for everyday transactions and "
        "short-term needs, not long-term growth. Keep one to three months of expenses here as a "
        "buffer; money beyond that earns more in deposits or investments.",
    ),
    KnowledgeDoc(
        "kb_fd", "IDBI Fixed Deposit", "IDBI Products / Deposits",
        "A Fixed Deposit (FD) locks a lump sum for a chosen tenure at a guaranteed interest rate, "
        "currently about 6.5% per year. Capital is protected and returns are assured, making FDs "
        "ideal for emergency funds and goals within a few years. Premature withdrawal usually incurs "
        "a small penalty.",
    ),
    KnowledgeDoc(
        "kb_elss", "IDBI Tax Saver ELSS (80C)", "IDBI Products / Tax Saving",
        "ELSS (Equity Linked Savings Scheme) is an equity mutual fund that qualifies for tax "
        "deduction under Section 80C, up to ₹1.5 lakh of investments per financial year. It has the "
        "shortest lock-in of all 80C options at three years. Because it invests in equities it carries "
        "market risk but has historically delivered higher long-term returns than PPF or FDs. Complete "
        "80C investments before March 31 to claim the deduction.",
    ),
    KnowledgeDoc(
        "kb_sip", "Systematic Investment Plan (SIP)", "IDBI Guidance / Investing",
        "A SIP invests a fixed amount in a mutual fund every month. It builds discipline and averages "
        "your purchase price across market ups and downs (rupee-cost averaging), so you don't need to "
        "time the market. Starting early and staying invested lets compounding work over years. Use the "
        "Goal Planner to compute the monthly SIP needed to reach a target.",
    ),
    KnowledgeDoc(
        "kb_index", "IDBI Nifty 50 Index Fund", "IDBI Products / Mutual Funds",
        "An index fund passively tracks the Nifty 50, giving low-cost, diversified exposure to India's "
        "largest companies. Expected long-run returns are around 11% per year with equity-level risk. "
        "Index funds suit long-term, hands-off investors who want broad market growth without picking "
        "individual stocks.",
    ),
    KnowledgeDoc(
        "kb_gold", "IDBI Gold ETF", "IDBI Products / Mutual Funds",
        "A Gold ETF gives exposure to gold prices without holding physical gold. Gold acts as a "
        "diversifier and an inflation hedge, often moving differently from equities. A small allocation "
        "(around 10%) can cushion a portfolio during market stress.",
    ),
    KnowledgeDoc(
        "kb_home_loan", "IDBI Home Loan", "IDBI Products / Loans",
        "A home loan finances property purchase, repaid via monthly EMIs over a long tenure. Prepaying "
        "principal early reduces total interest. Because a home loan is secured, its interest rate is far "
        "lower than a credit card's, so clear high-interest debt before prepaying a home loan.",
    ),
    KnowledgeDoc(
        "kb_nps", "National Pension System (NPS)", "IDBI Products / Retirement",
        "NPS is a low-cost, long-term retirement product with an additional tax deduction of up to "
        "₹50,000 under Section 80CCD(1B), over and above the 80C limit. It invests across equity and debt "
        "and is locked until retirement, making it suited to building a retirement corpus.",
    ),
    KnowledgeDoc(
        "kb_emergency", "Emergency Fund", "IDBI Guidance / Planning",
        "An emergency fund covers three to six months of expenses in safe, liquid instruments such as a "
        "savings account or liquid fund, so an unexpected cost or income gap doesn't force you into debt. "
        "Build it before taking on market risk with investments.",
    ),
    KnowledgeDoc(
        "kb_health", "Financial Health Score", "IDBI Guidance / Financial Health",
        "Your financial health score summarizes savings rate, debt level, emergency-fund coverage, "
        "investment allocation, and spending discipline into a single 0–100 number with a grade. Improving "
        "the weakest pillar first raises the score fastest.",
    ),
    KnowledgeDoc(
        "kb_budget", "Spending & Budgets", "IDBI Guidance / Spending",
        "Budgeting starts with categorizing spending — groceries, dining, transport, utilities, shopping — "
        "and setting a monthly limit per category. A common rule is to save at least 20% of take-home pay. "
        "The Spending Analytics tab flags categories drifting up and alerts you before you overspend.",
    ),
    KnowledgeDoc(
        "kb_fraud", "Fraud & Phishing Safety", "IDBI Security / Fraud",
        "Banks never ask for your OTP, PIN, CVV, or password by SMS, email, or call. Treat urgent messages "
        "about blocked accounts, KYC re-verification, lottery wins, or links to click as scams. If a "
        "transaction looks unfamiliar, freeze your card from the app and report it immediately.",
    ),
]
