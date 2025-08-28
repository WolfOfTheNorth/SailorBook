use anyhow::Result;
use epub::doc::EpubDoc;
use std::io::Cursor;

#[derive(Debug, Clone)]
pub struct ParsedEpub {
    pub title: String,
    pub author: String,
    pub chapters: Vec<ChapterContent>,
}

#[derive(Debug, Clone)]
pub struct ChapterContent {
    pub title: String,
    pub html_content: String,
    pub spine_index: usize,
}

pub fn parse_epub(epub_path: String) -> Result<ParsedEpub> {
    let mut doc = EpubDoc::new(&epub_path)?;
    
    let title = doc.mdata("title").unwrap_or_else(|| "Unknown Title".to_string());
    let author = doc.mdata("creator").unwrap_or_else(|| "Unknown Author".to_string());
    
    let mut chapters = Vec::new();
    
    for (spine_index, spine_id) in doc.spine.iter().enumerate() {
        if let Ok(content) = doc.get_resource_str(spine_id) {
            let chapter_title = extract_chapter_title(&content, spine_index);
            
            chapters.push(ChapterContent {
                title: chapter_title,
                html_content: content,
                spine_index,
            });
        }
    }
    
    Ok(ParsedEpub {
        title,
        author,
        chapters,
    })
}

fn extract_chapter_title(html_content: &str, spine_index: usize) -> String {
    use regex::Regex;
    
    let h1_re = Regex::new(r"<h1[^>]*>([^<]+)</h1>").unwrap();
    let h2_re = Regex::new(r"<h2[^>]*>([^<]+)</h2>").unwrap();
    let title_re = Regex::new(r"<title[^>]*>([^<]+)</title>").unwrap();
    
    if let Some(caps) = h1_re.captures(html_content) {
        return clean_title(&caps[1]);
    }
    
    if let Some(caps) = h2_re.captures(html_content) {
        return clean_title(&caps[1]);
    }
    
    if let Some(caps) = title_re.captures(html_content) {
        return clean_title(&caps[1]);
    }
    
    format!("Chapter {}", spine_index + 1)
}

fn clean_title(title: &str) -> String {
    title
        .trim()
        .replace('\n', ' ')
        .replace('\t', ' ')
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}