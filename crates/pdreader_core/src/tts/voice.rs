use crate::VoiceCfg;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoiceInfo {
    pub id: String,
    pub name: String,
    pub language: String,
    pub description: String,
    pub model_path: Option<String>,
}

impl Default for VoiceCfg {
    fn default() -> Self {
        Self {
            id: "en_us_default".to_string(),
            rate: 1.0,
            pitch: 1.0,
        }
    }
}

pub fn get_available_voices() -> Vec<VoiceInfo> {
    vec![
        VoiceInfo {
            id: "en_us_default".to_string(),
            name: "English (US) - Default".to_string(),
            language: "en-US".to_string(),
            description: "Standard American English voice".to_string(),
            model_path: Some("assets/models/en_us_default.onnx".to_string()),
        },
        VoiceInfo {
            id: "en_us_female".to_string(),
            name: "English (US) - Female".to_string(),
            language: "en-US".to_string(),
            description: "Female American English voice".to_string(),
            model_path: Some("assets/models/en_us_female.onnx".to_string()),
        },
    ]
}

pub fn validate_voice_config(cfg: &VoiceCfg) -> Result<(), String> {
    let available_voices = get_available_voices();
    
    if !available_voices.iter().any(|v| v.id == cfg.id) {
        return Err(format!("Voice '{}' not found", cfg.id));
    }
    
    if cfg.rate < 0.5 || cfg.rate > 3.0 {
        return Err("Rate must be between 0.5 and 3.0".to_string());
    }
    
    if cfg.pitch < 0.5 || cfg.pitch > 2.0 {
        return Err("Pitch must be between 0.5 and 2.0".to_string());
    }
    
    Ok(())
}