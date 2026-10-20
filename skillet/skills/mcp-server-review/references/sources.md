# Sources

Retrieved and checked on 2026-10-20. Refresh before citing in a report that needs current wording.

- **Model Context Protocol, Security Best Practices.** https://modelcontextprotocol.io/specification/latest/basic/security_best_practices (redirects to the dated docs page). Covers confused deputy, token passthrough, SSRF during OAuth discovery, state handle hijacking, and local server compromise including DNS rebinding. Basis for lens 2 and lens 5.
- **Model Context Protocol, Authorization.** https://modelcontextprotocol.io/specification/latest/basic/authorization. Audience-bound tokens and the ban on token passthrough. Basis for lens 2.
- **OWASP MCP Top 10.** https://owasp.org/projects/mcp-top-10. Risk categories for MCP-enabled systems. Used to sanity-check coverage across lenses.
- **OWASP MCP Security Cheat Sheet.** https://cheatsheetseries.owasp.org/cheatsheets/MCP_Security_Cheat_Sheet.html. Least privilege per server, authentication on remote endpoints, tool and description handling. Basis for lenses 1, 2, 4, and 7.
- **OWASP Top 10 for LLM Applications.** https://genai.owasp.org/llm-top-10/. Prompt injection, insecure output handling, excessive agency, and supply chain risks. Basis for lenses 1 and 6.
- **OWASP Agentic AI, Threats and Mitigations.** https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/. Tool misuse, privilege compromise, and memory or context poisoning in agent systems. Basis for lenses 1 and 6.
- **Invariant Labs, MCP Security Notification: Tool Poisoning Attacks.** https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks. Original write-up of hidden instructions in tool descriptions, including rug pulls and shadowing across servers. Basis for lens 7.

Notes:

- The spec and OWASP pages are living documents. Cite the section you rely on, and check the date on the page you retrieved.
- Vendor blogs that summarize these sources are not cited here. Prefer the primary pages above.
