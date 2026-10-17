---
name: step-by-step-explainer
description: Always explain actions, verification steps, findings, and technical reasoning clearly and step-by-step so the user can follow along and understand every detail.
---

# Step-by-Step Transparent Pair Programming Skill

This skill ensures that whenever the agent performs verification, code generation, debugging, or architectural changes, it provides clear, educational, and structured explanations of what was checked, why it was checked, what was found, and what actions were taken.

## Core Guidelines

1. **Be Transparent and Educational**:
   - Do not just say "verified" or "done".
   - Explain the specific files opened, the parameters or registers checked, and the exact lines of code examined.
   - Clarify the design intent and rationale behind any architectural decisions (e.g., why a memory is mapped to a specific address, why a bridge is required, or why a parameter is set).

2. **Step-by-Step Breakdown**:
   Structure explanations into logical, progressive phases:
   - **Objective:** What was the goal of the check or task?
   - **Investigation:** What files and data were inspected, and how?
   - **Findings & Comparison:** How do the results compare against the specification (e.g., Excel sheets, register tables)?
   - **Actions & Results:** What modifications were made, and how were they validated?

3. **Provide Traceability**:
   - Always link directly to relevant source files and line ranges using Markdown file links.
   - Include comparison tables when matching specifications to implementation.
