use anyhow::{anyhow, Result};
use colored::*;
use std::process::Command;

use crate::email::extract_unsubscribe_link;
use crate::himalaya::Himalaya;

pub async fn run(
    account: Option<String>,
    id: String,
    folder: String,
    show_only: bool,
) -> Result<()> {
    let himalaya = Himalaya::new(account);

    // Get raw message to find unsubscribe headers/links
    let raw_content = himalaya.read_message(&folder, &id, true)?;

    // Also get plain content for body scanning
    let plain_content = himalaya.read_message(&folder, &id, false)?;

    // Try to find unsubscribe link
    let link = extract_unsubscribe_link(&raw_content)
        .or_else(|| extract_unsubscribe_link(&plain_content));

    match link {
        Some(url) => {
            println!("{}", "Unsubscribe Link Found".green().bold());
            println!("{}", "═".repeat(40));
            println!();
            println!("{}", url.cyan());
            println!();

            if show_only {
                return Ok(());
            }

            // Try to open in browser
            println!("Opening in browser...");

            #[cfg(target_os = "linux")]
            let open_cmd = "xdg-open";

            #[cfg(target_os = "macos")]
            let open_cmd = "open";

            #[cfg(target_os = "windows")]
            let open_cmd = "start";

            let result = Command::new(open_cmd).arg(&url).spawn();

            match result {
                Ok(_) => {
                    println!("{} Opened in browser", "✓".green());
                    println!();
                    println!(
                        "{}",
                        "After unsubscribing, you can archive this email:".dimmed()
                    );
                    println!("  email-cli action archive {}", id.yellow());
                }
                Err(e) => {
                    println!(
                        "{} Could not open browser: {}",
                        "!".yellow(),
                        e
                    );
                    println!();
                    println!("Please open the link manually.");
                }
            }
        }
        None => {
            println!("{}", "No Unsubscribe Link Found".yellow().bold());
            println!();
            println!("This email doesn't contain an obvious unsubscribe link.");
            println!();
            println!("{}", "Suggestions:".dimmed());
            println!("  1. Read the full email for manual unsubscribe instructions:");
            println!("     email-cli read {}", id);
            println!("  2. Mark as spam to train the filter:");
            println!("     email-cli action spam {}", id);
            println!("  3. Archive if it's a one-time message:");
            println!("     email-cli action archive {}", id);

            return Err(anyhow!("No unsubscribe link found"));
        }
    }

    Ok(())
}
