use anyhow::Result;
use colored::*;
use serde_json::json;

use crate::email::EmailEnvelope;
use crate::himalaya::Himalaya;

pub async fn run(
    account: Option<String>,
    id: String,
    folder: String,
    json_output: bool,
    headers: bool,
) -> Result<()> {
    let himalaya = Himalaya::new(account);

    // Get envelope info
    let envelopes = himalaya.list_envelopes(&folder, 1, Some(&id))?;
    let envelope = envelopes
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(EmailEnvelope::from_json);

    // Get message content
    let content = himalaya.read_message(&folder, &id, headers)?;

    if json_output {
        let output = json!({
            "envelope": envelope,
            "content": content,
        });
        println!("{}", serde_json::to_string_pretty(&output)?);
        return Ok(());
    }

    // Formatted output
    let separator = "━".repeat(78);
    println!("{}", separator.dimmed());

    if let Some(ref env) = envelope {
        let from = if env.from_name.is_empty() {
            env.from_addr.clone()
        } else {
            format!("{} <{}>", env.from_name, env.from_addr)
        };

        println!("{}: {}", "From".cyan().bold(), from);
        println!("{}: {}", "To".cyan().bold(), env.to.join(", "));
        println!("{}: {}", "Subject".cyan().bold(), env.subject.bold());
        println!("{}: {}", "Date".cyan().bold(), env.date);

        if !env.flags.is_empty() {
            println!("{}: {}", "Flags".cyan().bold(), env.flags.join(", "));
        }
    }

    println!("{}", separator.dimmed());
    println!();
    println!("{}", content);

    Ok(())
}
