---
name: linear
description: Manage Linear issues, documents, and attachments from the CLI. Stash Claude plans as Linear documents.
user_invocable: false
---

# Linear CLI

Use the `linear` CLI (v1.10+) to interact with Linear from the command line.

## Stashing a plan to a Linear issue

When the user wants to save/stash a Claude plan (or any structured notes) to a Linear issue for later, use `linear document create`:

```bash
linear document create \
  --title "<descriptive title>" \
  --issue <ISSUE-ID> \
  --content "<markdown content>"
```

For longer content, write it to a temp file first and use `--content-file`:

```bash
linear document create \
  --title "<descriptive title>" \
  --issue <ISSUE-ID> \
  --content-file /tmp/plan.md
```

The document will appear linked to the issue in Linear's UI and is searchable, editable, and versioned.

## Attaching files to an issue

To attach a file (image, PDF, log, etc.) to an issue:

```bash
linear issue attach <ISSUE-ID> <filepath> \
  --title "Custom title" \
  --comment "Context about this attachment"
```

## Quick reference

| Action | Command |
|---|---|
| List my issues | `linear issue list` |
| View issue details | `linear issue view <ID>` |
| Create an issue | `linear issue create` |
| Update an issue | `linear issue update <ID>` |
| Add a comment | `linear issue comment <ID>` |
| Attach a file | `linear issue attach <ID> <file>` |
| Create a document | `linear document create --title "..." --issue <ID>` |
| View a document | `linear document view <ID>` |
| List documents | `linear document list` |
