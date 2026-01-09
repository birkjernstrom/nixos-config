use anyhow::Result;
use colored::*;
use std::io::{self, Read};

use crate::himalaya::Himalaya;

pub async fn run(
    account: Option<String>,
    to: Vec<String>,
    subject: String,
    body: Option<String>,
    cc: Vec<String>,
    in_reply_to: Option<String>,
) -> Result<()> {
    let himalaya = Himalaya::new(account);

    // Get body from stdin if not provided
    let message_body = match body {
        Some(b) => b,
        None => {
            eprintln!("{}", "Reading message body from stdin...".dimmed());
            eprintln!("{}", "(Press Ctrl+D when done)".dimmed());
            let mut buffer = String::new();
            io::stdin().read_to_string(&mut buffer)?;
            buffer
        }
    };

    // Build RFC 2822 message
    let mut message = String::new();

    // Headers
    message.push_str(&format!("To: {}\n", to.join(", ")));
    message.push_str(&format!("Subject: {}\n", subject));

    if !cc.is_empty() {
        message.push_str(&format!("Cc: {}\n", cc.join(", ")));
    }

    if let Some(ref reply_id) = in_reply_to {
        message.push_str(&format!("In-Reply-To: <{}>\n", reply_id));
        message.push_str(&format!("References: <{}>\n", reply_id));
    }

    message.push_str("Content-Type: text/plain; charset=utf-8\n");
    message.push_str("\n"); // End of headers

    // Body
    message.push_str(&message_body);

    // Show preview
    println!("{}", "Message Preview".bold());
    println!("{}", "═".repeat(50));
    println!();
    println!("{}: {}", "To".cyan(), to.join(", "));
    if !cc.is_empty() {
        println!("{}: {}", "Cc".cyan(), cc.join(", "));
    }
    println!("{}: {}", "Subject".cyan(), subject);
    if let Some(ref reply_id) = in_reply_to {
        println!("{}: {}", "In-Reply-To".cyan(), reply_id);
    }
    println!();
    println!("{}", "─".repeat(50).dimmed());
    println!();

    // Truncate preview if too long
    let preview: String = if message_body.len() > 500 {
        format!("{}...\n\n[Message truncated for preview]", &message_body[..500])
    } else {
        message_body.clone()
    };
    println!("{}", preview);

    println!();
    println!("{}", "─".repeat(50).dimmed());
    println!();

    // Confirm
    print!("Send this message? [y/N] ");
    io::Write::flush(&mut io::stdout())?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    if !input.trim().eq_ignore_ascii_case("y") {
        println!("Cancelled.");
        return Ok(());
    }

    // Send
    println!();
    print!("Sending... ");
    io::Write::flush(&mut io::stdout())?;

    himalaya.send_message(&message)?;

    println!("{}", "✓ Sent!".green().bold());

    Ok(())
}
