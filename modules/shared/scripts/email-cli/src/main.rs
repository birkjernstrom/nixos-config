mod commands;
mod email;
mod himalaya;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "email-cli")]
#[command(about = "Email management CLI for working through email backlog")]
#[command(version)]
struct Cli {
    /// Email account to use (as configured in himalaya)
    #[arg(short, long, global = true)]
    account: Option<String>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// List emails from a folder
    List {
        /// Folder to list (default: INBOX)
        #[arg(short, long, default_value = "INBOX")]
        folder: String,

        /// Number of emails to fetch
        #[arg(short = 'n', long, default_value = "50")]
        limit: u32,

        /// Search query (IMAP search syntax)
        #[arg(short, long)]
        query: Option<String>,

        /// Show only unread emails
        #[arg(short, long)]
        unread: bool,

        /// Output as JSON
        #[arg(short, long)]
        json: bool,
    },

    /// Read a specific email
    Read {
        /// Email ID
        id: String,

        /// Folder containing the email
        #[arg(short, long, default_value = "INBOX")]
        folder: String,

        /// Output as JSON
        #[arg(short, long)]
        json: bool,

        /// Include raw headers
        #[arg(short = 'H', long)]
        headers: bool,
    },

    /// Analyze emails for priority and unsubscribe candidates
    Analyze {
        /// Folder to analyze
        #[arg(short, long, default_value = "INBOX")]
        folder: String,

        /// Number of emails to analyze
        #[arg(short = 'n', long, default_value = "100")]
        limit: u32,

        /// Analysis type: all, priority, unsubscribe
        #[arg(short, long, default_value = "all")]
        r#type: String,

        /// Output as JSON
        #[arg(short, long)]
        json: bool,
    },

    /// Perform bulk actions on emails
    Action {
        /// Action to perform: archive, delete, spam, read, unread, star, unstar, move
        action: String,

        /// Email IDs to act on
        #[arg(required = true)]
        ids: Vec<String>,

        /// Source folder
        #[arg(short, long, default_value = "INBOX")]
        folder: String,

        /// Target folder (required for move action)
        #[arg(short, long)]
        target: Option<String>,

        /// Skip confirmation
        #[arg(short, long)]
        yes: bool,

        /// Dry run - show what would be done
        #[arg(long)]
        dry_run: bool,
    },

    /// List available email accounts
    Accounts {
        /// Output as JSON
        #[arg(short, long)]
        json: bool,
    },

    /// Extract unsubscribe link from an email
    Unsubscribe {
        /// Email ID
        id: String,

        /// Folder containing the email
        #[arg(short, long, default_value = "INBOX")]
        folder: String,

        /// Only show the link, don't open
        #[arg(long)]
        show_only: bool,
    },

    /// Show folders for the account
    Folders {
        /// Output as JSON
        #[arg(short, long)]
        json: bool,
    },

    /// Draft a reply to an email (outputs template)
    Reply {
        /// Email ID to reply to
        id: String,

        /// Folder containing the email
        #[arg(short, long, default_value = "INBOX")]
        folder: String,

        /// Reply all
        #[arg(short = 'a', long)]
        all: bool,

        /// Output as JSON
        #[arg(short, long)]
        json: bool,
    },

    /// Send a composed email
    Send {
        /// To address(es)
        #[arg(short, long, required = true)]
        to: Vec<String>,

        /// Subject
        #[arg(short, long)]
        subject: String,

        /// Body (or use stdin)
        #[arg(short, long)]
        body: Option<String>,

        /// CC addresses
        #[arg(long)]
        cc: Vec<String>,

        /// In-Reply-To message ID (for threading)
        #[arg(long)]
        in_reply_to: Option<String>,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::List {
            folder,
            limit,
            query,
            unread,
            json,
        } => commands::list::run(cli.account, folder, limit, query, unread, json).await,

        Commands::Read {
            id,
            folder,
            json,
            headers,
        } => commands::read::run(cli.account, id, folder, json, headers).await,

        Commands::Analyze {
            folder,
            limit,
            r#type,
            json,
        } => commands::analyze::run(cli.account, folder, limit, r#type, json).await,

        Commands::Action {
            action,
            ids,
            folder,
            target,
            yes,
            dry_run,
        } => commands::action::run(cli.account, action, ids, folder, target, yes, dry_run).await,

        Commands::Accounts { json } => commands::accounts::run(json).await,

        Commands::Unsubscribe {
            id,
            folder,
            show_only,
        } => commands::unsubscribe::run(cli.account, id, folder, show_only).await,

        Commands::Folders { json } => commands::folders::run(cli.account, json).await,

        Commands::Reply {
            id,
            folder,
            all,
            json,
        } => commands::reply::run(cli.account, id, folder, all, json).await,

        Commands::Send {
            to,
            subject,
            body,
            cc,
            in_reply_to,
        } => commands::send::run(cli.account, to, subject, body, cc, in_reply_to).await,
    }
}
