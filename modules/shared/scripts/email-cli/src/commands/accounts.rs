use anyhow::Result;
use colored::*;
use serde_json::json;

use crate::himalaya::Himalaya;

pub async fn run(json_output: bool) -> Result<()> {
    let accounts = Himalaya::get_accounts()?;

    if json_output {
        let output = json!({
            "accounts": accounts
        });
        println!("{}", serde_json::to_string_pretty(&output)?);
        return Ok(());
    }

    println!("{}", "Available Email Accounts".bold());
    println!("{}", "═".repeat(30));
    println!();

    for (i, account) in accounts.iter().enumerate() {
        if i == 0 {
            println!("  {} {} {}", "→".green(), account.cyan(), "(default)".dimmed());
        } else {
            println!("    {}", account.cyan());
        }
    }

    println!();
    println!(
        "{}",
        "Use -a/--account <name> to select an account".dimmed()
    );

    Ok(())
}
