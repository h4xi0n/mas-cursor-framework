# Review Profile: GenAI & LLM Systems (`genai`)

Specialized domain checklist for reviewing generative AI pipelines, prompt templates, tool schemas, and on-device SLM implementations.

---

## Invariants

1. **Prompt Hierarchy & XML Tagging:** All prompt templates must delimit context, system instructions, and untrusted user input using explicit XML boundary tags (e.g. `<system_instructions>`, `<context>`, `<user_input>`). Untrusted input must never be interpolated bare into instructions.
2. **Strict Tool Schemas:** Tool definitions must provide strict JSON schemas with fully specified types, descriptions, and `required` property arrays. Ambiguous types (`any`, bare object) are prohibited.
3. **On-Device SLM Hardware Guards:** Local on-device model execution (e.g. Gemma, MediaPipe) must guard model initialization with a runtime check requiring $\ge 6\text{GB}$ physical device RAM.
4. **Token Budget & Timeout Bounds:** Every model invocation must specify a max output token budget and deterministic network timeout (e.g. 30s) with coroutine cancellation support.
5. **Evaluation Suite Assertions:** GenAI features must include automated eval tests verifying answer faithfulness, context relevance, or schema adherence.

---

## Domain Checklist

Evaluate each item as `PASS`, `FAIL`, or `N/A`:

| Check Item | Requirement | Status | Notes |
|---|---|:---:|---|
| **Prompt XML Boundary Tags** | System, context, and user sections separated by XML tags. | | |
| **Strict Tool JSON Schema** | All properties typed, described, and listed in `required`. | | |
| **On-Device RAM Guard ($\ge 6\text{GB}$)** | Memory check precedes model load for on-device inference. | | |
| **Timeout & Cancellation** | LLM calls bound by cancellation token and timeout limit. | | |
| **Token Budget Capping** | `max_tokens` explicitly set to prevent runaway token spend. | | |
| **Fallback & Degradation** | Graceful handling for model rate-limits (HTTP 429) and outages. | | |
| **Evaluation Assertions** | Automated unit/eval tests assert output quality/validity. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: genai)`:

```markdown
## GenAI Specification & Evaluation Verification

| Check | Status | Notes |
|-------|:------:|-------|
| Prompt Hierarchy & XML Tagging | PASS / FAIL | <prompt structure check> |
| Tool Schema Strictness | PASS / FAIL / N/A | <JSON schema validation> |
| On-Device Hardware Guard (≥6GB RAM) | PASS / FAIL / N/A | <memory check presence> |
| Token Limits & Timeouts | PASS / FAIL | <budget & cancellation check> |
| Automated Eval Assertions | PASS / FAIL | <test suite evaluation> |
```
