## Portable OpenSource HyperRAM controller for FPGAs written in VHDL

HyperRAM is quite a beast! On the one hand, it offers advantages to hardware designers such as
low pin count, low power consumption and easy control. At least compared to modern DDR alternatives.
On the other hand, there are tons of nitty gritty details you need to know and take care of to
create a stable and realiable HyperRAM controller. Complex constraints and nasty phase shifts
just to name two of them.

![HyperRAM image](hyperram_img.jpg)

Therefore you do not want to reinvent the wheel and go through the joy and pain of implementing
a HyperRAM controller from scratch. Search no longer! You have found what you are looking
for: The [MJoergen/HyperRAM](https://github.com/MJoergen/HyperRAM) controller has the following
advantages:

* Easy to use
* Well documented
* Field proven stability
* Portable
* Very permissive [MIT license](https://github.com/MJoergen/HyperRAM/blob/main/LICENSE) that also allows commercial use

The controller is written in modern **VHDL-2008** and you can of course use it without
any modifications in your **Verilog** Designs.

### Features

This implementation has support for:

* Maximum HyperRAM clock speed of 100 MHz
* Variable latency
* Configuration registers read and write
* Identification registers read
* Automatic configuration of latency mode upon reset
* 16-bit Avalon Memory Map interface including burst mode

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
