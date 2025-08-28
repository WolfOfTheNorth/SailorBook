use flutter_rust_bridge::frb;

pub mod epub;
pub mod tts;
pub mod cache;
pub mod manifest;

pub use epub::*;
pub use tts::*;
pub use cache::*;
pub use manifest::*;

#[derive(Debug, Clone, PartialEq)]
pub struct VoiceCfg {
    pub id: String,
    pub rate: f32,
    pub pitch: f32,
}

#[derive(Debug, Clone)]
pub struct BookMeta {
    pub id: String,
    pub title: String,
    pub author: String,
    pub cover_url: Option<String>,
    pub download_url: String,
    pub file_size_mb: f64,
}

#[derive(Debug, Clone)]
pub struct Chapter {
    pub id: u32,
    pub title: String,
    pub paragraph_ids: Vec<u32>,
}

#[derive(Debug, Clone)]
pub struct Paragraph {
    pub id: u32,
    pub chapter_id: u32,
    pub text: String,
    pub word_count: u32,
}

#[derive(Debug, Clone)]
pub struct Position {
    pub chapter_id: u32,
    pub paragraph_id: u32,
    pub offset_ms: u64,
}

#[derive(Debug, Clone)]
pub struct Manifest {
    pub book_id: String,
    pub title: String,
    pub author: String,
    pub chapters: Vec<Chapter>,
    pub paragraphs: Vec<Paragraph>,
    pub last_position: Option<Position>,
}

#[frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[frb(sync)]
pub fn init_logger() {
    env_logger::init();
}