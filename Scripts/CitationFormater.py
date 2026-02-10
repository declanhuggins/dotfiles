#!/usr/bin/env python3
"""
This script processes an input markdown file in two steps:
1. It searches for markdown links (e.g. [text](URL)) and replaces them with inline HTML citations.
   A "Works Cited" section is appended with each unique URL.
2. It then converts the generated HTML citation markup into plain markdown references,
   which is suitable for processing with remark or remark-html.

Usage:
    python process_and_convert.py input.md output.md
"""

import re
import argparse

def process_markdown(text):
    """
    Replace markdown links with inline HTML citations and append a Works Cited section.
    
    Args:
        text (str): The original markdown text.
    
    Returns:
        str: The markdown text with inline HTML citations and a Works Cited section appended.
    """
    # Regular expression to match markdown links: [text](URL)
    pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

    # Dictionary to store each unique URL and assign a reference number.
    references = {}
    reference_counter = 1
    ref_list = []  # List to store references in the order they are found.

    def replace_link(match):
        nonlocal reference_counter
        url = match.group(2)
        # If this URL is new, assign it a new reference number.
        if url not in references:
            references[url] = reference_counter
            ref_list.append((reference_counter, url))
            reference_counter += 1

        ref_number = references[url]
        # Create a clickable inline superscript citation.
        return f"<sup><a href='#ref-{ref_number}' id='cit-{ref_number}'>[{ref_number}]</a></sup>"

    # Replace all markdown links with our custom inline citation.
    new_text = pattern.sub(replace_link, text)

    # Append the Works Cited section.
    new_text += "\n\n## Works Cited\n"
    for num, url in ref_list:
        # Wrap the URL inside an <a> tag so that it is clickable.
        new_text += f"<p><a name='ref-{num}'></a><a href='#cit-{num}'>[{num}]</a>: <a href='{url}' target='_blank'>{url}</a></p>\n"

    return new_text

def convert_markdown(md_text):
    """
    Convert inline HTML citation markup into plain markdown notation.
    
    Two transformations occur:
      1. Inline citations such as:
             <sup><a href='#ref-1' id='cit-1'>[1]</a></sup>
         are replaced with just:
             [1]
      2. Works Cited entries, e.g.:
             <p><a name='ref-1'></a><a href='#cit-1'>[1]</a>: <a href='URL' target='_blank'>URL</a></p>
         are transformed into plain markdown reference lines:
             [1]: URL

    Args:
        md_text (str): The markdown text containing HTML citation markup.
    
    Returns:
        str: The markdown text with plain markdown citation references.
    """
    # Replace inline HTML citations: <sup><a ...>[1]</a></sup> -> [1]
    inline_pattern = re.compile(r'<sup>\s*<a\s+[^>]*>(.*?)</a>\s*</sup>')
    converted_text = inline_pattern.sub(r'\1', md_text)

    # Convert Works Cited paragraphs.
    works_cited_pattern = re.compile(
        r"<p>\s*(?:<a\s+name='[^']*'></a>)?\s*<a\s+href='#cit-[^']*'>(\[[0-9]+\])</a>:\s*<a\s+href='([^']+)'[^>]*>[^<]*</a>\s*</p>",
        re.IGNORECASE
    )
    converted_text = works_cited_pattern.sub(r'\1: \2', converted_text)

    return converted_text

def main():
    parser = argparse.ArgumentParser(
        description='Generate inline citations from markdown links and convert them to plain markdown for remark.'
    )
    parser.add_argument('input_file', help='Path to the input markdown file')
    parser.add_argument('output_file', help='Path to the output markdown file')
    args = parser.parse_args()

    # Read the input markdown content.
    with open(args.input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # First, process the markdown to generate inline citations and a Works Cited section.
    processed_content = process_markdown(content)
    # Then, convert the citation HTML to plain markdown reference style.
    final_content = convert_markdown(processed_content)

    # Write the final output to the output file.
    with open(args.output_file, 'w', encoding='utf-8') as f:
        f.write(final_content)

    print(f"Processing complete. Output written to '{args.output_file}'.")

if __name__ == '__main__':
    main()
