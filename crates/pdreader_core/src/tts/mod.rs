use crate::VoiceCfg;
use anyhow::Result;
use flutter_rust_bridge::frb;

pub mod engine;
pub mod voice;

pub use engine::*;
pub use voice::*;

#[frb]
pub async fn synthesize(paragraph: String, cfg: VoiceCfg) -> Result<Vec<u8>> {
    let engine = TtsEngine::new()?;
    engine.synthesize_text(&paragraph, &cfg).await
}

#[frb]
pub async fn prebuffer(paragraphs: Vec<String>, cfg: VoiceCfg, n: usize) -> Result<Vec<Vec<u8>>> {
    let engine = TtsEngine::new()?;
    let mut results = Vec::new();
    
    for paragraph in paragraphs.into_iter().take(n) {
        let audio = engine.synthesize_text(&paragraph, &cfg).await?;
        results.push(audio);
    }
    
    Ok(results)
}

#[frb(sync)]
pub fn cache_key_for(paragraph: String, cfg: VoiceCfg) -> String {
    use blake3::Hasher;
    
    let mut hasher = Hasher::new();
    hasher.update(paragraph.as_bytes());
    hasher.update(cfg.id.as_bytes());
    hasher.update(&cfg.rate.to_le_bytes());
    hasher.update(&cfg.pitch.to_le_bytes());
    
    format!("{}", hasher.finalize().to_hex())
}