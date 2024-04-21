# icon-subset-generator
Icon subset generator from website project files

## How its works

1. Scan files like html, js, json, php and extract their icons
2. Compile these icons into a font format (eot, svg, ttf, woff and woff2) using the provided svgs
3. The result is a set of optimized fonts and their respective CSS ready to use on your website.

## Requirements
 
- [Font Custom](https://github.com/FontCustom/fontcustom) and its dependencies
- [fantasticon](https://github.com/tancredi/fantasticon)

## Use

1. Put the files to scan in the **input** folder
2. Insert all svgs that you need in the **svgs** folder
3. Run the **iconsubset.sh** script

_Note: All predefined params (input path, output path, icon prefixes, etc.) can be changed in the config section of the **iconsubset.sh** file_

## Installation notes

```
# On Debian and Ubuntu install ruby dev packages first
sudo apt install ruby-dev

# Install ttfautohint to get generated a font properly hinted
sudo apt install ttfautohint

# Font custom
sudo apt install zlib1g-dev fontforge
git clone https://github.com/bramstein/sfnt2woff-zopfli.git sfnt2woff-zopfli && cd sfnt2woff-zopfli && make && sudo mv sfnt2woff-zopfli /usr/local/bin/sfnt2woff
git clone --recursive https://github.com/google/woff2.git && cd woff2 && make clean all && sudo mv woff2_compress /usr/local/bin/ && sudo mv woff2_decompress /usr/local/bin/
sudo gem install fontcustom

# fantasticon
npm install -g fantasticon
```
