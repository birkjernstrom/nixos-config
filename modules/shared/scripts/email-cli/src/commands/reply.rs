use anyhow::Result;
use colored::*;
use serde_json::json;

use crate::email::EmailEnvelope;
use crate::himalaya::Himalaya;

pub async fn run(
    account: Option<String>,
    id: String,
    folder: String,
    reply_all: bool,
    json_output: bool,
) -> Result<()> {
    let himalaya = Himalaya::new(account);

    // Get envelope info
    let envelopes = himalaya.list_envelopes(&folder, 1, Some(&id))?;
    let envelope = envelopes
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(EmailEnvelope::from_json);

    // Get message content
    let content = himalaya.read_message(&folder, &id, false)?;

    let envelope = match envelope {
        Some(e) => e,
        None => {
            println!("Email not found: {}", id);
            return Ok(());
        }
    };

    // Build reply template
    let to = if reply_all {
        let mut recipients = vec![envelope.from_addr.clone()];
        recipients.extend(envelope.to.clone());
        recipients
    } else {
        vec![envelope.from_addr.clone()]
    };

    let subject = if envelope.subject.starts_with("Re:") {
        envelope.subject.clone()
    } else {
        format!("Re: {}", envelope.subject)
    };

    // Quote original message
    let quoted: String = content
        .lines()
        .map(|line| format!("> {}", line))
        .collect::<Vec<_>>()
        .join("\n");

    let reply_body = format!(
        "\n\n\n--- Original Message ---\nFrom: {} <{}>\nDate: {}\n\n{}",
        envelope.from_name, envelope.from_addr, envelope.date, quoted
    );

    if json_output {
        let output = json!({
            "to": to,
            "subject": subject,
            "in_reply_to": id,
            "original": {
                "from_name": envelope.from_name,
                "from_addr": envelope.from_addr,
                "date": envelope.date,
                "subject": envelope.subject,
            },
            "quoted_body": quoted,
            "template": reply_body,
        });
        println!("{}", serde_json::to_string_pretty(&output)?);
        return Ok(());
    }

    // Display reply template
    println!("{}", "Reply Template".bold());
    println!("{}", "═".repeat(50));
    println!();
    println!("{}: {}", "To".cyan(), to.join(", "));
    println!("{}: {}", "Subject".cyan(), subject);
    println!();
    println!("{}", "─".repeat(50).dimmed());
    println!();
    println!("{}", "[Your reply here]".yellow());
    println!();
    println!("{}", reply_body.dimmed());
    println!();
    println!("{}", "─".repeat(50).dimmed());
    println!();
    println!("{}", "To send this reply:".dimmed());
    println!(
        "  email-cli send --to {} --subject \"{}\" --body \"Your message\" --in-reply-to {}",
        to.first().unwrap_or(&"".to_string()),
        subject,
        id
    );

    Ok(())
}
