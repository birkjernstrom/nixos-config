use anyhow::{anyhow, Result};
use serde_json::Value;
use std::process::Command;

pub struct Himalaya {
    account: Option<String>,
}

impl Himalaya {
    pub fn new(account: Option<String>) -> Self {
        Self { account }
    }

    fn base_cmd(&self) -> Command {
        let mut cmd = Command::new("himalaya");
        if let Some(ref acc) = self.account {
            cmd.args(["--account", acc]);
        }
        cmd
    }

    pub fn list_envelopes(&self, folder: &str, limit: u32, query: Option<&str>) -> Result<Value> {
        let mut cmd = self.base_cmd();
        cmd.args([
            "envelope",
            "list",
            "--folder",
            folder,
            "--page-size",
            &limit.to_string(),
            "--output",
            "json",
        ]);

        if let Some(q) = query {
            cmd.args(["--", q]);
        }

        let output = cmd.output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        let json: Value = serde_json::from_slice(&output.stdout)?;
        Ok(json)
    }

    pub fn read_message(&self, folder: &str, id: &str, raw: bool) -> Result<String> {
        let mut cmd = self.base_cmd();
        cmd.args(["message", "read", "--folder", folder]);
        if raw {
            cmd.arg("--raw");
        }
        cmd.arg(id);

        let output = cmd.output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    }

    pub fn move_envelope(&self, folder: &str, target: &str, id: &str) -> Result<()> {
        let mut cmd = self.base_cmd();
        cmd.args(["envelope", "move", "--folder", folder, target, id]);

        let output = cmd.output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        Ok(())
    }

    pub fn flag_add(&self, folder: &str, id: &str, flag: &str) -> Result<()> {
        let mut cmd = self.base_cmd();
        cmd.args(["envelope", "flag", "add", "--folder", folder, id, flag]);

        let output = cmd.output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        Ok(())
    }

    pub fn flag_remove(&self, folder: &str, id: &str, flag: &str) -> Result<()> {
        let mut cmd = self.base_cmd();
        cmd.args(["envelope", "flag", "remove", "--folder", folder, id, flag]);

        let output = cmd.output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        Ok(())
    }

    pub fn list_folders(&self) -> Result<Value> {
        let mut cmd = self.base_cmd();
        cmd.args(["folder", "list", "--output", "json"]);

        let output = cmd.output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        let json: Value = serde_json::from_slice(&output.stdout)?;
        Ok(json)
    }

    pub fn send_message(&self, message: &str) -> Result<()> {
        let mut cmd = self.base_cmd();
        cmd.args(["message", "send"]);
        cmd.stdin(std::process::Stdio::piped());

        let mut child = cmd.spawn()?;
        if let Some(ref mut stdin) = child.stdin {
            use std::io::Write;
            stdin.write_all(message.as_bytes())?;
        }

        let output = child.wait_with_output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("himalaya failed: {}", stderr));
        }

        Ok(())
    }

    pub fn get_accounts() -> Result<Vec<String>> {
        // Parse himalaya config to get accounts
        // For now, we'll just return accounts from config
        let output = Command::new("himalaya")
            .args(["account", "list", "--output", "json"])
            .output()?;

        if !output.status.success() {
            // Fallback: try to get default account
            return Ok(vec!["default".to_string()]);
        }

        let json: Value = serde_json::from_slice(&output.stdout)?;
        let accounts = json
            .as_array()
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.get("name").and_then(|n| n.as_str()).map(String::from))
                    .collect()
            })
            .unwrap_or_else(|| vec!["default".to_string()]);

        Ok(accounts)
    }
}

// Gmail folder mappings
pub fn gmail_folder(name: &str) -> &str {
    match name.to_lowercase().as_str() {
        "archive" | "all" => "[Gmail]/All Mail",
        "trash" | "deleted" => "[Gmail]/Trash",
        "spam" | "junk" => "[Gmail]/Spam",
        "starred" => "[Gmail]/Starred",
        "important" => "[Gmail]/Important",
        "drafts" => "[Gmail]/Drafts",
        "sent" => "[Gmail]/Sent Mail",
        _ => name,
    }
}
