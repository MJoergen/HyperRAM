## Portable OpenSource HyperRAM controller for FPGAs written in VHDL

HyperRAM is quite a beast! On the one hand, it offers advantages to hardware designers such as
low pin count, low power consumption and easy control. At least compared to modern DDR alternatives.
On the other hand, there are tons of nitty gritty details you need to know to create a stable
and realiable HyperRAM controller. Complex constraints and nasty phase shifts just to name
two of them.

* 
It is hard to find a decent OpenSource 
his repository contains a portable OpenSource HyperRAM controller for FPGAs written in VHDL. I'm writing my own implementation because I've looked at several other implementations, and they all seemed lacking in various regards (features, stability, portability, etc.)

The HyperRAM controller in this repository is a complete rewrite from scratch, and is provided with a MIT license.

Learn more by reading the documentation in this repository or by browsing the companion website: https://mjoergen.github.io/HyperRAM/
Features

This implementation has support for:

    Maximum HyperRAM clock speed of 100 MHz.
    Variable latency.
    Configuration registers read and write
    Identification registers read
    Automatic configuration of latency mode upon reset.
    16-bit Avalon Memory Map interface including burst mode.
    Written for VHDL-2008

You can use the [editor on GitHub](https://github.com/MJoergen/HyperRAM/edit/gh-pages/index.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [Basic writing and formatting syntax](https://docs.github.com/en/github/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/MJoergen/HyperRAM/settings/pages). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://docs.github.com/categories/github-pages-basics/) or [contact support](https://support.github.com/contact) and we’ll help you sort it out.
