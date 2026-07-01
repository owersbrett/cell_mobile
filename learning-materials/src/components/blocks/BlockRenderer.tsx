import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import katex from 'katex';
import type { ContentBlock } from '../../types/lesson';

function Md({ children }: { children: string }) {
  return (
    <div className="md">
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{children}</ReactMarkdown>
    </div>
  );
}

function Equation({ tex, caption }: { tex: string; caption?: string }) {
  let html = '';
  try {
    html = katex.renderToString(tex, { displayMode: true, throwOnError: false });
  } catch {
    html = `<code>${tex}</code>`;
  }
  return (
    <div className="eq">
      <div dangerouslySetInnerHTML={{ __html: html }} />
      {caption && <div className="cap">{caption}</div>}
    </div>
  );
}

function Media({ block }: { block: Extract<ContentBlock, { type: 'video' | 'embed' }> }) {
  const src =
    block.type === 'video'
      ? block.provider === 'youtube'
        ? `https://www.youtube-nocookie.com/embed/${block.src}`
        : block.src
      : block.url;
  return (
    <figure>
      <div className="media-frame">
        <iframe
          src={src}
          title={block.caption ?? 'embedded media'}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
          loading="lazy"
        />
      </div>
      {block.caption && <figcaption className="cap">{block.caption}</figcaption>}
    </figure>
  );
}

export function Block({ block }: { block: ContentBlock }) {
  switch (block.type) {
    case 'markdown':
      return <Md>{block.markdown}</Md>;
    case 'callout':
      return (
        <div className={`callout ${block.variant}`}>
          <div className="tag">{block.variant}</div>
          <Md>{block.markdown}</Md>
        </div>
      );
    case 'quote':
      return (
        <blockquote className="lq">
          {block.markdown}
          {block.cite && <cite>— {block.cite}</cite>}
        </blockquote>
      );
    case 'equation':
      return <Equation tex={block.tex} caption={block.caption} />;
    case 'image':
      return (
        <figure>
          <img src={block.src} alt={block.alt} loading="lazy" />
          {block.caption && <figcaption className="cap">{block.caption}</figcaption>}
        </figure>
      );
    case 'video':
    case 'embed':
      return <Media block={block} />;
    case 'gameLink':
      return (
        <a className="game-link" href={block.target}>
          ▶ {block.label}
        </a>
      );
    default:
      return null;
  }
}

export function Blocks({ blocks }: { blocks: ContentBlock[] }) {
  return (
    <>
      {blocks.map((b, i) => (
        <Block key={i} block={b} />
      ))}
    </>
  );
}
