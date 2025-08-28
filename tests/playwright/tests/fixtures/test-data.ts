export const testBooks = [
  {
    id: 'test-book-1',
    title: 'Alice\'s Adventures in Wonderland',
    author: 'Lewis Carroll',
    coverUrl: 'https://covers.openlibrary.org/b/id/123456-M.jpg',
    downloadUrl: 'https://archive.org/download/alicesadventures/alicesadventures.epub',
    fileSizeMb: 1.2,
  },
  {
    id: 'test-book-2',
    title: 'The Adventures of Tom Sawyer',
    author: 'Mark Twain',
    coverUrl: 'https://covers.openlibrary.org/b/id/789012-M.jpg',
    downloadUrl: 'https://archive.org/download/tomsawyer/tomsawyer.epub',
    fileSizeMb: 2.1,
  },
  {
    id: 'test-book-3',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    coverUrl: 'https://covers.openlibrary.org/b/id/345678-M.jpg',
    downloadUrl: 'https://archive.org/download/prideandprejudice/prideandprejudice.epub',
    fileSizeMb: 1.8,
  },
];

export const testManifest = {
  bookId: 'test-book-1',
  title: 'Alice\'s Adventures in Wonderland',
  author: 'Lewis Carroll',
  chapters: [
    {
      id: 0,
      title: 'Down the Rabbit-Hole',
      paragraphIds: [0, 1, 2, 3, 4],
    },
    {
      id: 1,
      title: 'The Pool of Tears',
      paragraphIds: [5, 6, 7, 8, 9],
    },
    {
      id: 2,
      title: 'A Caucus-Race and a Long Tale',
      paragraphIds: [10, 11, 12, 13, 14],
    },
  ],
  paragraphs: [
    {
      id: 0,
      chapterId: 0,
      text: 'Alice was beginning to get very tired of sitting by her sister on the bank.',
      wordCount: 16,
    },
    {
      id: 1,
      chapterId: 0,
      text: 'So she was considering in her own mind, when suddenly a White Rabbit with pink eyes ran close by her.',
      wordCount: 20,
    },
    {
      id: 2,
      chapterId: 0,
      text: 'There was nothing so very remarkable in that; nor did Alice think it so very much out of the way.',
      wordCount: 20,
    },
    {
      id: 3,
      chapterId: 0,
      text: 'But when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, Alice started to her feet.',
      wordCount: 21,
    },
    {
      id: 4,
      chapterId: 0,
      text: 'In another moment down went Alice after it, never once considering how in the world she was to get out again.',
      wordCount: 20,
    },
    // More paragraphs would be added for other chapters...
    {
      id: 5,
      chapterId: 1,
      text: 'Either the well was very deep, or she fell very slowly.',
      wordCount: 12,
    },
    {
      id: 6,
      chapterId: 1,
      text: 'She had plenty of time as she went down to look about her and to wonder what was going to happen next.',
      wordCount: 21,
    },
    {
      id: 7,
      chapterId: 1,
      text: 'First, she tried to look down and make out what she was coming to.',
      wordCount: 14,
    },
    {
      id: 8,
      chapterId: 1,
      text: 'After a while, finding that nothing more happened, she decided to look about her.',
      wordCount: 14,
    },
    {
      id: 9,
      chapterId: 1,
      text: 'Down, down, down. Would the fall never come to an end!',
      wordCount: 12,
    },
    {
      id: 10,
      chapterId: 2,
      text: 'At last the Mouse, who seemed to be a person of authority among them.',
      wordCount: 14,
    },
    {
      id: 11,
      chapterId: 2,
      text: 'They were indeed a queer-looking party that assembled on the bank.',
      wordCount: 11,
    },
    {
      id: 12,
      chapterId: 2,
      text: 'The first question of course was, how to get dry again.',
      wordCount: 11,
    },
    {
      id: 13,
      chapterId: 2,
      text: 'They had a consultation about this, and after a few minutes it seemed quite natural to Alice.',
      wordCount: 17,
    },
    {
      id: 14,
      chapterId: 2,
      text: 'The Mouse was speaking to her in an angry tone.',
      wordCount: 10,
    },
  ],
  lastPosition: null,
};

export const mockApiResponses = {
  searchBooks: {
    docs: testBooks.map(book => ({
      key: `/works/${book.id}`,
      title: book.title,
      author_name: [book.author],
      cover_i: parseInt(book.coverUrl?.split('/').pop()?.split('-')[0] || '0'),
      first_publish_year: 1865,
      ia: [book.id.replace('test-', 'archive-')],
    })),
  },
  
  downloadBook: {
    success: true,
    path: '/mock/path/to/book.epub',
  },
  
  buildManifest: testManifest,
  
  synthesizeAudio: {
    audioData: new Array(1000).fill(0).map((_, i) => i % 256),
  },
  
  voiceConfigs: [
    {
      id: 'en_us_default',
      name: 'English (US) - Default',
      language: 'en-US',
      description: 'Standard American English voice',
    },
    {
      id: 'en_us_female',
      name: 'English (US) - Female',
      language: 'en-US',
      description: 'Female American English voice',
    },
  ],
};