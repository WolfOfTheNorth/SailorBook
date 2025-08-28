use crate::{Manifest, Chapter, Paragraph};
use anyhow::Result;
use std::path::Path;

pub mod parser;
pub mod normalizer;

pub use parser::*;
pub use normalizer::*;

#[flutter_rust_bridge::frb]
pub fn build_manifest(epub_path: String) -> Result<Manifest> {
    let path = Path::new(&epub_path);
    
    if !path.exists() {
        anyhow::bail!("EPUB file does not exist: {}", epub_path);
    }
    
    let parsed_epub = parse_epub(epub_path.clone())?;
    let normalized_content = normalize_content(&parsed_epub)?;
    
    Ok(create_manifest(epub_path, normalized_content))
}

fn create_manifest(epub_path: String, content: NormalizedContent) -> Manifest {
    let book_id = generate_book_id(&epub_path);
    
    let mut paragraphs = Vec::new();
    let mut chapters = Vec::new();
    let mut paragraph_id = 0u32;
    
    for (chapter_idx, chapter_content) in content.chapters.iter().enumerate() {
        let chapter_id = chapter_idx as u32;
        let mut paragraph_ids = Vec::new();
        
        for paragraph_text in &chapter_content.paragraphs {
            let word_count = paragraph_text.split_whitespace().count() as u32;
            
            paragraphs.push(Paragraph {
                id: paragraph_id,
                chapter_id,
                text: paragraph_text.clone(),
                word_count,
            });
            
            paragraph_ids.push(paragraph_id);
            paragraph_id += 1;
        }
        
        chapters.push(Chapter {
            id: chapter_id,
            title: chapter_content.title.clone(),
            paragraph_ids,
        });
    }
    
    Manifest {
        book_id,
        title: content.title,
        author: content.author,
        chapters,
        paragraphs,
        last_position: None,
    }
}

fn generate_book_id(epub_path: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    
    let mut hasher = DefaultHasher::new();
    epub_path.hash(&mut hasher);
    format!("book_{:x}", hasher.finish())
}