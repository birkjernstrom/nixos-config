# Email Management Skill

You are helping the user manage their email backlog efficiently using the `email-cli` tool. This skill helps identify low-priority emails, bulk archive/unsubscribe, and craft responses to important messages.

## Available Commands

The `email-cli` tool provides these commands:

### Listing and Reading Emails
```bash
# List emails in INBOX (default)
email-cli list

# List with options
email-cli list --limit 100 --unread
email-cli list --folder "[Gmail]/All Mail" --json

# Switch accounts
email-cli list --account work
email-cli list --account personal

# Read a specific email
email-cli read <email-id>
email-cli read <email-id> --json
```

### Analyzing Emails
```bash
# Full analysis of inbox
email-cli analyze --limit 100

# Find high priority emails only
email-cli analyze --type priority

# Find unsubscribe candidates
email-cli analyze --type unsubscribe --json

# Find low priority emails
email-cli analyze --type low
```

### Taking Actions
```bash
# Archive emails (moves to All Mail, removes from INBOX)
email-cli action archive <id1> <id2> <id3>

# Delete emails (moves to Trash)
email-cli action delete <id1>

# Mark as spam
email-cli action spam <id1>

# Mark as read/unread
email-cli action read <id1> <id2>
email-cli action unread <id1>

# Star/unstar
email-cli action star <id1>

# Move to folder
email-cli action move <id1> --target "Projects/Important"

# Bulk action with confirmation skip
email-cli action archive <ids...> --yes

# Dry run to see what would happen
email-cli action archive <ids...> --dry-run
```

### Unsubscribe
```bash
# Extract and open unsubscribe link
email-cli unsubscribe <email-id>

# Just show the link
email-cli unsubscribe <email-id> --show-only
```

### Managing Accounts and Folders
```bash
# List configured accounts
email-cli accounts

# List folders for an account
email-cli folders
email-cli folders --account work
```

### Replying to Emails
```bash
# Get reply template
email-cli reply <email-id>
email-cli reply <email-id> --all  # Reply all
email-cli reply <email-id> --json

# Send an email
email-cli send --to "user@example.com" --subject "Subject" --body "Message"
```

## Workflow Recommendations

### 1. Email Triage Session
When the user wants to work through their email backlog:

1. **Start with analysis**:
   ```bash
   email-cli analyze --limit 100 --json
   ```
   This gives you structured data about priority levels and unsubscribe candidates.

2. **Handle unsubscribe candidates first**:
   - Show the user the list of potential newsletters/marketing emails
   - For each, offer to:
     - Extract unsubscribe link: `email-cli unsubscribe <id>`
     - Archive directly: `email-cli action archive <id>`
     - Mark as spam: `email-cli action spam <id>`

3. **Bulk archive low priority**:
   After reviewing, archive low-priority emails in bulk:
   ```bash
   email-cli action archive <id1> <id2> <id3> --yes
   ```

4. **Focus on high priority**:
   Read and help compose responses for important emails.

### 2. Multiple Gmail Accounts
The user has multiple Gmail accounts. Always:
- Ask which account they want to work with at the start
- Use `--account <name>` consistently
- Check accounts with `email-cli accounts`

### 3. Crafting Responses
When helping with important emails:
1. Read the full email: `email-cli read <id>`
2. Get reply template: `email-cli reply <id> --json`
3. Help draft a response considering:
   - The sender's tone and formality
   - The context and any deadlines mentioned
   - Keep responses concise but complete
4. Confirm before sending

## Best Practices

1. **Always use JSON output** (`--json`) when you need to process data programmatically
2. **Use dry-run** before bulk operations to verify actions
3. **Check the analysis reasons** to understand why emails were categorized
4. **Be conservative with spam marking** - archive is safer for legitimate but unwanted emails
5. **Preserve threading** when replying by using `--in-reply-to`

## Configuration Note

The `email-cli` tool requires `himalaya` to be configured with Gmail accounts. The configuration is typically in `~/.config/himalaya/config.toml`. Each Gmail account needs:
- IMAP access enabled
- App-specific password (if 2FA is enabled)
- Proper OAuth2 or password configuration
