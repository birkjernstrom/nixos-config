use anyhow::Result;
use colored::*;
use tabled::{Table, Tabled};

use crate::email::{EmailAnalysis, EmailEnvelope, Priority};
use crate::himalaya::Himalaya;

#[derive(Tabled)]
struct AnalysisRow {
    #[tabled(rename = "ID")]
    id: String,
    #[tabled(rename = "Priority")]
    priority: String,
    #[tabled(rename = "From")]
    from: String,
    #[tabled(rename = "Subject")]
    subject: String,
    #[tabled(rename = "Unsub?")]
    unsubscribe: String,
}

pub async fn run(
    account: Option<String>,
    folder: String,
    limit: u32,
    analysis_type: String,
    json_output: bool,
) -> Result<()> {
    let himalaya = Himalaya::new(account);

    let envelopes = himalaya.list_envelopes(&folder, limit, None)?;

    let emails: Vec<EmailEnvelope> = envelopes
        .as_array()
        .map(|arr| arr.iter().filter_map(EmailEnvelope::from_json).collect())
        .unwrap_or_default();

    let analyses: Vec<EmailAnalysis> = emails.iter().map(EmailAnalysis::analyze).collect();

    // Filter based on type
    let filtered: Vec<&EmailAnalysis> = match analysis_type.as_str() {
        "priority" | "high" => analyses
            .iter()
            .filter(|a| a.priority == Priority::High)
            .collect(),
        "unsubscribe" | "unsub" => analyses
            .iter()
            .filter(|a| a.unsubscribe_candidate)
            .collect(),
        "low" => analyses
            .iter()
            .filter(|a| a.priority == Priority::Low)
            .collect(),
        _ => analyses.iter().collect(), // "all"
    };

    if json_output {
        println!("{}", serde_json::to_string_pretty(&filtered)?);
        return Ok(());
    }

    // Summary
    let total = analyses.len();
    let high = analyses
        .iter()
        .filter(|a| a.priority == Priority::High)
        .count();
    let medium = analyses
        .iter()
        .filter(|a| a.priority == Priority::Medium)
        .count();
    let low = analyses
        .iter()
        .filter(|a| a.priority == Priority::Low)
        .count();
    let unsub = analyses.iter().filter(|a| a.unsubscribe_candidate).count();

    println!("{}", "Email Analysis Report".bold());
    println!("{}", "═".repeat(50));
    println!();
    println!("Total analyzed: {}", total.to_string().cyan());
    println!(
        "  {} High priority",
        high.to_string().red().bold()
    );
    println!(
        "  {} Medium priority",
        medium.to_string().yellow()
    );
    println!("  {} Low priority", low.to_string().dimmed());
    println!(
        "  {} Unsubscribe candidates",
        unsub.to_string().magenta()
    );
    println!();

    if filtered.is_empty() {
        println!("No emails match the filter criteria.");
        return Ok(());
    }

    // Display based on type
    match analysis_type.as_str() {
        "priority" | "high" => {
            println!("{}", "═══ HIGH PRIORITY ═══".red().bold());
            println!();
            for analysis in &filtered {
                print_analysis(analysis);
            }
        }
        "unsubscribe" | "unsub" => {
            println!("{}", "═══ UNSUBSCRIBE CANDIDATES ═══".magenta().bold());
            println!();
            for analysis in &filtered {
                print_analysis(analysis);
            }

            // Print IDs for easy bulk action
            println!();
            println!("{}", "Quick action:".dimmed());
            let ids: Vec<&str> = filtered.iter().map(|a| a.id.as_str()).collect();
            println!(
                "  email-cli action archive {}",
                ids.join(" ").yellow()
            );
        }
        "low" => {
            println!("{}", "═══ LOW PRIORITY ═══".dimmed().bold());
            println!();

            let rows: Vec<AnalysisRow> = filtered
                .iter()
                .map(|a| AnalysisRow {
                    id: a.id.clone(),
                    priority: format_priority(&a.priority),
                    from: truncate(&a.from_addr, 30),
                    subject: truncate(&a.subject, 40),
                    unsubscribe: if a.unsubscribe_candidate {
                        "Yes".to_string()
                    } else {
                        "".to_string()
                    },
                })
                .collect();

            let table = Table::new(rows).to_string();
            println!("{}", table);
        }
        _ => {
            // All - show table view
            let rows: Vec<AnalysisRow> = filtered
                .iter()
                .map(|a| AnalysisRow {
                    id: a.id.clone(),
                    priority: format_priority(&a.priority),
                    from: truncate(&a.from_addr, 30),
                    subject: truncate(&a.subject, 40),
                    unsubscribe: if a.unsubscribe_candidate {
                        "Yes".to_string()
                    } else {
                        "".to_string()
                    },
                })
                .collect();

            let table = Table::new(rows).to_string();
            println!("{}", table);
        }
    }

    Ok(())
}

fn format_priority(priority: &Priority) -> String {
    match priority {
        Priority::High => "HIGH".red().bold().to_string(),
        Priority::Medium => "MED".yellow().to_string(),
        Priority::Low => "LOW".dimmed().to_string(),
    }
}

fn truncate(s: &str, max: usize) -> String {
    if s.len() > max {
        format!("{}...", &s[..max - 3])
    } else {
        s.to_string()
    }
}

fn print_analysis(analysis: &EmailAnalysis) {
    let from = if analysis.from_name.is_empty() {
        analysis.from_addr.clone()
    } else {
        format!("{} <{}>", analysis.from_name, analysis.from_addr)
    };

    println!("[{}] {}", analysis.id.cyan(), from);
    println!("    Subject: {}", analysis.subject);
    if !analysis.reasons.is_empty() {
        println!("    Reasons: {}", analysis.reasons.join(", ").dimmed());
    }
    println!();
}
