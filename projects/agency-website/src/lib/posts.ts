import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';
import { remark } from 'remark';
import html from 'remark-html';

const postsDirectory = process.env.CONTENT_DIR 
  ? path.resolve(process.env.CONTENT_DIR) 
  : path.join(process.cwd(), '../../content/blog');

export interface PostData {
  slug: string;
  title: string;
  date: string;
  author: string;
  tags: string[];
  status: string;
  description?: string;
  excerpt?: string;
  contentHtml?: string;
}

export function getSortedPostsData(): PostData[] {
  // Check if directory exists
  if (!fs.existsSync(postsDirectory)) {
    console.warn(`Content directory not found at: ${postsDirectory}`);
    return [];
  }

  const fileNames = fs.readdirSync(postsDirectory);
  const allPostsData = fileNames.map((fileName) => {
    // Remove ".md" from file name to get id
    const slug = fileName.replace(/\.md$/, '');

    // Read markdown file as string
    const fullPath = path.join(postsDirectory, fileName);
    const fileContents = fs.readFileSync(fullPath, 'utf8');

    // Use gray-matter to parse the post metadata section
    const matterResult = matter(fileContents);

    // Combine the data with the id
    return {
      slug,
      ...(matterResult.data as Omit<PostData, 'slug'>),
    };
  });

  // Filter out drafts if in production? Maybe not for now.
  const publishedPosts = allPostsData.filter(post => {
      // Allow explicit 'Ready' or allow all in development
      if (process.env.NODE_ENV === 'development') return true;
      return post.status === 'Ready';
  });

  // Sort posts by date
  return publishedPosts.sort((a, b) => {
    if (a.date < b.date) {
      return 1;
    } else {
      return -1;
    }
  });
}

export async function getPostData(slug: string): Promise<PostData> {
  const fullPath = path.join(postsDirectory, `${slug}.md`);
  const fileContents = fs.readFileSync(fullPath, 'utf8');

  // Use gray-matter to parse the post metadata section
  const matterResult = matter(fileContents);

  // Use remark to convert markdown into HTML string
  const processedContent = await remark()
    .use(html)
    .process(matterResult.content);
  const contentHtml = processedContent.toString();

  return {
    slug,
    contentHtml,
    ...(matterResult.data as Omit<PostData, 'slug' | 'contentHtml'>),
  };
}
