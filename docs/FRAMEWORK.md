# GUIDELINE.md

Last Updated: 2024-12-21

## Purpose

This document defines how to maintain the business documentation for both humans
and LLMs.

## Documentation Architecture

```
/
├── Core/
│   ├── vision.md      # Why we exist, what success looks like
│   ├── strategy.md    # How we'll achieve our vision
│   └── metrics.md     # How we measure progress
│
├── Product/
│   ├── features/      # What we're building
│   ├── users/         # Who we're building for
│   └── tech/          # How we're building it
│
├── Growth/
│   ├── acquisition/   # How we get users
│   └── retention/     # How we keep users
│
└── Business/
    ├── model.md       # How we make money
    └── operations.md  # How we run things
```

## Key Principles

1. **Simplicity First**

   - Keep structure minimal but extensible
   - One concern per document
   - Avoid redundancy across documents

2. **Action-Oriented**

   - Focus on actionable information
   - Include clear next steps where applicable
   - Link decisions to metrics and outcomes

3. **Living Documentation**

   - Regular updates to reflect current state
   - Archive outdated information instead of deleting
   - Track key decisions and their context

## Document Standards

### 1. Every Document Should Have

- Clear purpose statement
- Last updated date

### 2. Writing Style

- Be concise and actionable, but also should briefly explain the reasoning. So
  people can understand why a decision is made.
- Use bullet points over paragraphs
- Include examples where possible
- Link to supporting data/evidence

### 3. An "Other Notes" section in the end

- To keep the food for thoughts. Some information is not used directly for the
  decisions in the current version, but may have an impact when the document
  evolve.
- Use bullet points.
- You can remove one note if it's incorporated into the main sections.
- You should consider add one note if something is removed from the main
  sections.
- Otherwise, the notes should be perseved with minimumal edit.

## Guidelines for LLMs

1. When Helping with Documents:

   - Focus on actionable insights
   - Maintain existing structure
   - Link to relevant metrics
   - Suggest concrete next steps

2. Priority Order for Updates:

   - Critical business metrics
   - User-facing features
   - Growth initiatives
   - Internal processes

3. Question Framework:

   - "Does this improve user value?"
   - "Is this measurable?"
   - "What's the next action?"
