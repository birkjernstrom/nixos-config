use anyhow::Result;
use colored::*;
use tabled::{Table, Tabled};

use crate::email::EmailEnvelope;
use crate::himalaya::Himalaya;

#[derive(Tabled)]
struct EmailRow {
    #[tabled(rename = "ID")]
    id: String,
    #[tabled(rename = "From")]
    from: String,
    #[tabled(rename = "Subject")]
    subject: String,
    #[tabled(rename = "Date")]
    date: String,
    #[tabled(rename = "Flags")]
    flags: String,
}

pub async fn run(
    account: Option<String>,
    folder: String,
    limit: u32,
    query: Option<String>,
    unread: bool,
    json: bool,
) -> Result<()> {
    let himalaya = Himalaya::new(account);

    // Build query
    let search_query = match (query, unread) {
        (Some(q), true) => Some(format!("{} AND NOT SEEN", q)),
        (Some(q), false) => Some(q),
        (None, true) => Some("NOT SEEN".to_string()),
        (None, false) => None,
    };

    let envelopes = himalaya.list_envelopes(&folder, limit, search_query.as_deref())?;

    if json {
        println!("{}", serde_json::to_string_pretty(&envelopes)?);
        return Ok(());
    }

    let emails: Vec<EmailEnvelope> = envelopes
        .as_array()
        .map(|arr| arr.iter().filter_map(EmailEnvelope::from_json).collect())
        .unwrap_or_default();

    if emails.is_empty() {
        println!("No emails found in {}", folder);
        return Ok(());
    }

    let rows: Vec<EmailRow> = emails
        .iter()
        .map(|e| {
            let from = if e.from_name.is_empty() {
                e.from_addr.clone()
            } else {
                format!("{} <{}>", e.from_name, e.from_addr)
            };

            // Truncate long fields
            let from = if from.len() > 35 {
                format!("{}...", &from[..32])
            } else {
                from
            };

            let subject = if e.subject.len() > 50 {
                format!("{}...", &e.subject[..47])
            } else {
                e.subject.clone()
            };

            // Format flags
            let mut flag_chars = String::new();
            if !e.is_read() {
                flag_chars.push('●'); // unread
            }
            if e.is_starred() {
                flag_chars.push('★'); // starred
            }

            EmailRow {
                id: e.id.clone(),
                from,
                subject,
                date: e.date.clone(),
                flags: flag_chars,
            }
        })
        .collect();

    println!(
        "{} emails in {}",
        emails.len().to_string().cyan(),
        folder.green()
    );
    println!();

    let table = Table::new(rows).to_string();
    println!("{}", table);

    Ok(())
}
