use anyhow::Result;
use colored::*;
use tabled::{Table, Tabled};

use crate::himalaya::Himalaya;

#[derive(Tabled)]
struct FolderRow {
    #[tabled(rename = "Name")]
    name: String,
    #[tabled(rename = "Delimiter")]
    delimiter: String,
}

pub async fn run(account: Option<String>, json_output: bool) -> Result<()> {
    let himalaya = Himalaya::new(account);
    let folders = himalaya.list_folders()?;

    if json_output {
        println!("{}", serde_json::to_string_pretty(&folders)?);
        return Ok(());
    }

    let folder_list: Vec<FolderRow> = folders
        .as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|f| {
                    let name = f.get("name")?.as_str()?.to_string();
                    let delimiter = f
                        .get("delimiter")
                        .and_then(|d| d.as_str())
                        .unwrap_or("/")
                        .to_string();
                    Some(FolderRow { name, delimiter })
                })
                .collect()
        })
        .unwrap_or_default();

    println!("{}", "Email Folders".bold());
    println!("{}", "═".repeat(40));
    println!();

    if folder_list.is_empty() {
        println!("No folders found.");
        return Ok(());
    }

    // Group by Gmail system folders vs custom
    let gmail_folders: Vec<&FolderRow> = folder_list
        .iter()
        .filter(|f| f.name.starts_with("[Gmail]"))
        .collect();

    let custom_folders: Vec<&FolderRow> = folder_list
        .iter()
        .filter(|f| !f.name.starts_with("[Gmail]") && f.name != "INBOX")
        .collect();

    // Show INBOX first
    if let Some(inbox) = folder_list.iter().find(|f| f.name == "INBOX") {
        println!("  {} {}", "→".green(), inbox.name.cyan().bold());
    }

    if !gmail_folders.is_empty() {
        println!();
        println!("  {}", "Gmail System Folders:".dimmed());
        for folder in gmail_folders {
            let display_name = folder.name.replace("[Gmail]/", "  ");
            println!("    {}", display_name);
        }
    }

    if !custom_folders.is_empty() {
        println!();
        println!("  {}", "Custom Folders:".dimmed());
        for folder in custom_folders {
            println!("    {}", folder.name.green());
        }
    }

    println!();
    println!("{}", format!("Total: {} folders", folder_list.len()).dimmed());

    Ok(())
}
