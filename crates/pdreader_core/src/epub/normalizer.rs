use crate::epub::parser::ParsedEpub;
use anyhow::Result;
use regex::Regex;

#[derive(Debug, Clone)]
pub struct NormalizedContent {
    pub title: String,
    pub author: String,
    pub chapters: Vec<NormalizedChapter>,
}

#[derive(Debug, Clone)]
pub struct NormalizedChapter {
    pub title: String,
    pub paragraphs: Vec<String>,
}

pub fn normalize_content(parsed_epub: &ParsedEpub) -> Result<NormalizedContent> {
    let mut normalized_chapters = Vec::new();
    
    for chapter in &parsed_epub.chapters {
        let text_content = html_to_text(&chapter.html_content);
        let paragraphs = extract_paragraphs(&text_content);
        
        if !paragraphs.is_empty() {
            normalized_chapters.push(NormalizedChapter {
                title: chapter.title.clone(),
                paragraphs,
            });
        }
    }
    
    Ok(NormalizedContent {
        title: parsed_epub.title.clone(),
        author: parsed_epub.author.clone(),
        chapters: normalized_chapters,
    })
}

fn html_to_text(html: &str) -> String {
    html2text::from_read(html.as_bytes(), 80)
}

fn extract_paragraphs(text: &str) -> Vec<String> {
    let cleaned_text = clean_text(text);
    
    let paragraphs: Vec<String> = cleaned_text
        .split("\n\n")
        .map(|p| p.trim())
        .filter(|p| !p.is_empty())
        .filter(|p| p.len() > 10) // Filter out very short paragraphs
        .filter(|p| !is_boilerplate(p))
        .map(|p| normalize_paragraph(p))
        .collect();
    
    paragraphs
}

fn clean_text(text: &str) -> String {
    let re = Regex::new(r"\s+").unwrap();
    re.replace_all(text, " ").trim().to_string()
}

fn is_boilerplate(paragraph: &str) -> bool {
    let boilerplate_patterns = [
        "Project Gutenberg",
        "www.gutenberg.org",
        "End of Project Gutenberg",
        "*** START OF THE PROJECT",
        "*** END OF THE PROJECT",
        "CHAPTER",
        "Table of Contents",
    ];
    
    let lower_paragraph = paragraph.to_lowercase();
    boilerplate_patterns
        .iter()
        .any(|pattern| lower_paragraph.contains(&pattern.to_lowercase()))
}

fn normalize_paragraph(paragraph: &str) -> String {
    paragraph
        .lines()
        .map(|line| line.trim())
        .filter(|line| !line.is_empty())
        .collect::<Vec<_>>()
        .join(" ")
        .trim()
        .to_string()
}