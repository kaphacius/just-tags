<p align="center">
  <img width="256" height="256" src="https://github.com/kaphacius/just-tags/blob/main/JustTags/Resources/Assets.xcassets/AppIcon.appiconset/icon_512_256x2.png?raw=true">
</p>

# JustTags

JustTags in a macOS app for working with BER-TLV EMV tags.


## Features

<details><summary>Decode the tags from base64 or hex strings into a comprehensible list.</summary>
<p><img src="/Screenshots/00_parse.png?raw=true"></p></details>

<details><summary>Filter the decoded tags by tag, name, or description.</summary>
<p><img src="/Screenshots/01_filter.png?raw=true"></p></details>

<details><summary>Fully decode the tag value for specific tags (`9F33`, `95` etc).</summary>
<p><img src="/Screenshots/02_view.png?raw=true"></p></details>

<details><summary>View additional tag info (source, format, kernel).</summary>
<p><img src="/Screenshots/02_view.png?raw=true"></p></details>

<details><summary>Select and copy tags as hex string.</summary>
<p><img src="/Screenshots/03_copy.png?raw=true"></p></details>

<details><summary>Diff 2 tag lists against each other.</summary>
<p><img src="/Screenshots/04_diff.png?raw=true"></p></details>

<details><summary>Rename window tabs.</summary>
<p><img src="/Screenshots/05_rename_tab.png?raw=true"></p></details>

## How to use

Clone the project

```bash
git clone https://github.com/kaphacius/just-tags
```

Go to the project directory

```bash
cd just-tags
```

Open with Xcode

```bash
xed .
```

Build and run with `Command + R`

### Command-line support
If you want to open the application and pass the data from command-line, the following options are available:
- Custom URL schemes. Run `open justtags://main/nzMDKAjI` OR `open justtags://main/9F33032808C8` from command-line.
- Piping the output into a custom function. Set it like this:
1. Add the following to your `~/.zshrc` or `~/.bashrc`:
```bash
justtags() {
  read tags
  open justtags://main/$tags
}
```
2. Run `source ~/.zshrc` or `source ~/.bashrc`.
3. Use the new function `echo "9F33032808C8" | justtags` OR `echo "nzMDKAjI" | justtags`.

## Contributing

Contributions are always welcome!

Please open an [issue](https://github.com/kaphacius/just-tags/issues/new?labels=bug&title=A+minor+bug) if you spot a bug, or an [enhancement](https://github.com/kaphacius/just-tags/issues/new?labels=enhancement&title=A+great+idea) if you have an idea for a great feature.

## License

[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/)


## Alternative Tools

Eftlab's [BP-Tools](https://www.eftlab.com/bp-tools/)

Emvlab's [tlvtool](http://www.emvlab.org/tlvutils/)

Binaryfoo's [emv-bertlv](https://github.com/binaryfoo/emv-bertlv)
