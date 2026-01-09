use anyhow::{anyhow, Result};
use colored::*;
use std::io::{self, Write};

use crate::himalaya::{gmail_folder, Himalaya};

pub async fn run(
    account: Option<String>,
    action: String,
    ids: Vec<String>,
    folder: String,
    target: Option<String>,
    skip_confirm: bool,
    dry_run: bool,
) -> Result<()> {
    // Validate action
    let valid_actions = [
        "archive", "delete", "spam", "read", "unread", "star", "unstar", "move",
    ];
    if !valid_actions.contains(&action.as_str()) {
        return Err(anyhow!(
            "Invalid action: {}. Valid actions: {}",
            action,
            valid_actions.join(", ")
        ));
    }

    // Validate move requires target
    if action == "move" && target.is_none() {
        return Err(anyhow!("Move action requires --target folder"));
    }

    let himalaya = Himalaya::new(account);

    // Confirmation
    if !skip_confirm && !dry_run {
        println!(
            "About to {} {} email(s):",
            action.yellow().bold(),
            ids.len().to_string().cyan()
        );
        println!("  IDs: {}", ids.join(", "));
        println!("  From folder: {}", folder.green());
        if let Some(ref t) = target {
            println!("  To folder: {}", t.green());
        }
        println!();

        print!("Continue? [y/N] ");
        io::stdout().flush()?;

        let mut input = String::new();
        io::stdin().read_line(&mut input)?;

        if !input.trim().eq_ignore_ascii_case("y") {
            println!("Cancelled.");
            return Ok(());
        }
    }

    let mut success = 0;
    let mut failed = 0;

    for id in &ids {
        let result = execute_action(&himalaya, &action, id, &folder, target.as_deref(), dry_run);

        match result {
            Ok(()) => {
                if dry_run {
                    println!(
                        "{} Would {} email {}",
                        "[DRY RUN]".dimmed(),
                        action,
                        id.cyan()
                    );
                } else {
                    println!("{} {} email {}", "✓".green(), action, id.cyan());
                }
                success += 1;
            }
            Err(e) => {
                println!("{} Failed to {} email {}: {}", "✗".red(), action, id, e);
                failed += 1;
            }
        }
    }

    println!();
    println!(
        "Completed: {} successful, {} failed",
        success.to_string().green(),
        failed.to_string().red()
    );

    if failed > 0 {
        return Err(anyhow!("Some operations failed"));
    }

    Ok(())
}

fn execute_action(
    himalaya: &Himalaya,
    action: &str,
    id: &str,
    folder: &str,
    target: Option<&str>,
    dry_run: bool,
) -> Result<()> {
    if dry_run {
        return Ok(());
    }

    match action {
        "archive" => {
            himalaya.move_envelope(folder, gmail_folder("archive"), id)?;
        }
        "delete" => {
            himalaya.move_envelope(folder, gmail_folder("trash"), id)?;
        }
        "spam" => {
            himalaya.move_envelope(folder, gmail_folder("spam"), id)?;
        }
        "read" => {
            himalaya.flag_add(folder, id, "Seen")?;
        }
        "unread" => {
            himalaya.flag_remove(folder, id, "Seen")?;
        }
        "star" => {
            himalaya.flag_add(folder, id, "Flagged")?;
        }
        "unstar" => {
            himalaya.flag_remove(folder, id, "Flagged")?;
        }
        "move" => {
            let target_folder = target.ok_or_else(|| anyhow!("Target folder required"))?;
            let resolved = gmail_folder(target_folder);
            himalaya.move_envelope(folder, resolved, id)?;
        }
        _ => {
            return Err(anyhow!("Unknown action: {}", action));
        }
    }

    Ok(())
}
