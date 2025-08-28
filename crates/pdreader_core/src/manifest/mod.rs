use crate::{Manifest, Position};
use anyhow::Result;
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use std::path::Path;
use tokio::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ManifestFile {
    manifest: Manifest,
    created_at: i64,
    updated_at: i64,
}

#[frb]
pub async fn save_manifest(manifest_path: String, manifest: Manifest) -> Result<()> {
    let timestamp = chrono::Utc::now().timestamp();
    
    let manifest_file = ManifestFile {
        manifest,
        created_at: timestamp,
        updated_at: timestamp,
    };
    
    let json = serde_json::to_string_pretty(&manifest_file)?;
    fs::write(&manifest_path, json).await?;
    
    Ok(())
}

#[frb]
pub async fn load_manifest(manifest_path: String) -> Result<Option<Manifest>> {
    let path = Path::new(&manifest_path);
    
    if !path.exists() {
        return Ok(None);
    }
    
    let content = fs::read_to_string(&manifest_path).await?;
    let manifest_file: ManifestFile = serde_json::from_str(&content)?;
    
    Ok(Some(manifest_file.manifest))
}

#[frb]
pub async fn update_last_position(
    manifest_path: String,
    position: Position,
) -> Result<()> {
    if let Some(mut manifest) = load_manifest(manifest_path.clone()).await? {
        manifest.last_position = Some(position);
        save_manifest(manifest_path, manifest).await?;
    }
    
    Ok(())
}

#[frb]
pub async fn get_last_position(manifest_path: String) -> Result<Option<Position>> {
    if let Some(manifest) = load_manifest(manifest_path).await? {
        Ok(manifest.last_position)
    } else {
        Ok(None)
    }
}