use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmailEnvelope {
    pub id: String,
    pub from_addr: String,
    pub from_name: String,
    pub to: Vec<String>,
    pub subject: String,
    pub date: String,
    pub flags: Vec<String>,
}

impl EmailEnvelope {
    pub fn from_json(value: &Value) -> Option<Self> {
        Some(Self {
            id: value.get("id")?.as_str()?.to_string(),
            from_addr: value
                .get("from")
                .and_then(|f| f.get("addr"))
                .and_then(|a| a.as_str())
                .unwrap_or("")
                .to_string(),
            from_name: value
                .get("from")
                .and_then(|f| f.get("name"))
                .and_then(|n| n.as_str())
                .unwrap_or("")
                .to_string(),
            to: value
                .get("to")
                .and_then(|t| t.as_array())
                .map(|arr| {
                    arr.iter()
                        .filter_map(|v| v.get("addr").and_then(|a| a.as_str()).map(String::from))
                        .collect()
                })
                .unwrap_or_default(),
            subject: value
                .get("subject")
                .and_then(|s| s.as_str())
                .unwrap_or("(no subject)")
                .to_string(),
            date: value
                .get("date")
                .and_then(|d| d.as_str())
                .unwrap_or("")
                .to_string(),
            flags: value
                .get("flags")
                .and_then(|f| f.as_array())
                .map(|arr| {
                    arr.iter()
                        .filter_map(|v| v.as_str().map(String::from))
                        .collect()
                })
                .unwrap_or_default(),
        })
    }

    pub fn is_read(&self) -> bool {
        self.flags.iter().any(|f| f == "Seen")
    }

    pub fn is_starred(&self) -> bool {
        self.flags.iter().any(|f| f == "Flagged")
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Priority {
    High,
    Medium,
    Low,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmailAnalysis {
    pub id: String,
    pub from_addr: String,
    pub from_name: String,
    pub subject: String,
    pub priority: Priority,
    pub unsubscribe_candidate: bool,
    pub reasons: Vec<String>,
}

impl EmailAnalysis {
    pub fn analyze(envelope: &EmailEnvelope) -> Self {
        let mut priority = Priority::Medium;
        let mut unsubscribe_candidate = false;
        let mut reasons = Vec::new();

        let from_addr_lower = envelope.from_addr.to_lowercase();
        let subject_lower = envelope.subject.to_lowercase();

        // Unsubscribe patterns - sender patterns
        let unsubscribe_sender_patterns = [
            "noreply@",
            "no-reply@",
            "newsletter@",
            "notifications@",
            "updates@",
            "marketing@",
            "promo@",
            "news@",
            "digest@",
            "mailer@",
            "hello@",
            "team@",
            "donotreply@",
            "do-not-reply@",
            "bounce@",
            "campaigns@",
            "announce@",
        ];

        for pattern in &unsubscribe_sender_patterns {
            if from_addr_lower.contains(pattern) {
                unsubscribe_candidate = true;
                priority = Priority::Low;
                reasons.push(format!("sender pattern: {}", pattern));
                break;
            }
        }

        // Newsletter subject patterns
        let newsletter_patterns = [
            "newsletter",
            "digest",
            "weekly update",
            "monthly update",
            "daily digest",
            "bulletin",
            "roundup",
            "recap",
        ];

        for pattern in &newsletter_patterns {
            if subject_lower.contains(pattern) {
                unsubscribe_candidate = true;
                priority = Priority::Low;
                reasons.push(format!("newsletter pattern: {}", pattern));
                break;
            }
        }

        // Promotional patterns
        let promo_patterns = [
            r"\d+%\s*off",
            "sale",
            "discount",
            "deal",
            "limited time",
            "exclusive offer",
            "special offer",
            "free shipping",
            "promo code",
            "coupon",
            "save now",
            "act now",
            "don't miss",
            "flash sale",
        ];

        for pattern in &promo_patterns {
            let re = Regex::new(&format!("(?i){}", pattern)).unwrap();
            if re.is_match(&envelope.subject) {
                unsubscribe_candidate = true;
                priority = Priority::Low;
                reasons.push(format!("promotional: {}", pattern));
                break;
            }
        }

        // Social media notifications
        let social_patterns = [
            "liked your",
            "commented on",
            "mentioned you",
            "followed you",
            "new follower",
            "new connection",
            "shared your",
            "tagged you",
        ];

        for pattern in &social_patterns {
            if subject_lower.contains(pattern) {
                priority = Priority::Low;
                reasons.push(format!("social notification: {}", pattern));
                break;
            }
        }

        // Important patterns - these override low priority
        let important_patterns = [
            "invoice",
            "payment",
            "receipt",
            "urgent",
            "action required",
            "confirm",
            "verify",
            "password",
            "security alert",
            "security notice",
            "interview",
            "job offer",
            "offer letter",
            "contract",
            "deadline",
            "expiring",
            "expires",
            "important:",
            "immediate",
            "asap",
            "response needed",
            "your order",
            "shipped",
            "delivered",
            "bank",
            "tax",
        ];

        for pattern in &important_patterns {
            if subject_lower.contains(pattern) {
                priority = Priority::High;
                unsubscribe_candidate = false;
                reasons.clear();
                reasons.push(format!("important: {}", pattern));
                break;
            }
        }

        // If unread and not already categorized as high, bump to medium
        if !envelope.is_read() && priority == Priority::Low {
            priority = Priority::Medium;
            reasons.push("unread email".to_string());
        }

        Self {
            id: envelope.id.clone(),
            from_addr: envelope.from_addr.clone(),
            from_name: envelope.from_name.clone(),
            subject: envelope.subject.clone(),
            priority,
            unsubscribe_candidate,
            reasons,
        }
    }
}

/// Extract unsubscribe link from email content
pub fn extract_unsubscribe_link(content: &str) -> Option<String> {
    // Look for List-Unsubscribe header first
    let list_unsub_re = Regex::new(r"List-Unsubscribe:\s*<([^>]+)>").unwrap();
    if let Some(caps) = list_unsub_re.captures(content) {
        let link = caps.get(1).unwrap().as_str();
        if link.starts_with("http") {
            return Some(link.to_string());
        }
    }

    // Look for common unsubscribe link patterns in body
    let patterns = [
        r#"href=["']([^"']*unsubscribe[^"']*)["']"#,
        r#"href=["']([^"']*optout[^"']*)["']"#,
        r#"href=["']([^"']*opt-out[^"']*)["']"#,
        r#"href=["']([^"']*remove[^"']*)["']"#,
        r"(https?://[^\s<>\"']*unsubscribe[^\s<>\"']*)",
        r"(https?://[^\s<>\"']*optout[^\s<>\"']*)",
        r"(https?://[^\s<>\"']*opt-out[^\s<>\"']*)",
    ];

    for pattern in &patterns {
        let re = Regex::new(&format!("(?i){}", pattern)).unwrap();
        if let Some(caps) = re.captures(content) {
            return Some(caps.get(1).unwrap().as_str().to_string());
        }
    }

    None
}
