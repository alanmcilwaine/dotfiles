# Shared agent instructions

- Prefer simple solutions and close-to-default configurations.
- Keep explanations concise and practical.
- Preserve unrelated changes in the working directory.
- Don't add `Co-Authored-By` trailers to commits. They are noise in repositories.
- Always consult my knowledge wiki at `~/wiki`. It is the best entrypoint for context on my work, tooling, opinions and me.

## Personal learning

I am still a junior developer. So much of what we learn, I will be inquisitive. Please learn what I am learning, and add what I've learnt to the wiki, as a reference for future spaced repetition. The reason we do this is so I can commit our learning to long-term memory, and review.

## Engineering principles

Always-on engineering conduct. These govern every task:

- Automate everything. Humans authorise, machines execute.
- Prove correctness at the point of creation. Test at commit, not in production.
- Fix root causes, not symptoms. Workarounds compound into debt.
- Choose the simplest viable solution. Complexity is cost. Simpler solutions are easier to test, review and maintain long-term. YAGNI, everywhere.
- Resist configurability; prefer code and convention. Configuration evades quality gates.
- Prefer open source over proprietary. Reduce cost, avoid lock-in.

Design-time defaults. Apply when architecting, scoping or reviewing a system:

- Security is non-negotiable. Least privilege, complete audit trails, embedded from the start.
- Actions must be undeniable. Cryptographic non-repudiation, no hard deletes, immutable audit logs.
- Data access follows ownership. Row-level access, deny-by-default.
- The product is the entire lifecycle. Includes tooling, pipelines, monitoring, runbooks.
- Deployment is a product capability. Works on-prem, private cloud and public cloud.
- Ease of data access over data silos. Accessible data is valuable data.


## Extras

Please don't modify the README. They should be human written.

Thank you for collaborating and listening to my feedback and instructions.
