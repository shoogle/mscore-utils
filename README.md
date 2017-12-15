`mscore-utils`
==============

Scripts to manipulate [MuseScore](https://github.com/musescore/MuseScore/) files from the command line. These scripts operate on files in MuseScore's native MSCX format, including in its compressed MSCZ form.

## IMPORTANT!

MuseScore is under active development and its file formats can change at any time. The MSCX and MSCZ formats are *intentionally undocumented* as they are not considered suitable for editing with tools other than MuseScore.

If you want to work with digital sheet music files from the command line consider using a well-documented universal format like MusicXML, which has a mature set of tools for analyse and conversion (e.g. music21). You can use MuseScore to convert MSCX and MSCZ files to MusicXML for use with another program:

    mscore infile.mscz -o outfile.xml

These scripts in `mscore-utils` are strictly intended for preforming operations on MuseScore files *where the desired output is another MuseScore file*, or any other use cases where conversion to another format is not an option.

## Requirements

All of the scripts in this repository require Bash (version 4+ is strongly recommended). You will also need Git (recent version) to be able to contribute, and to get the full benefits of `mscore-utils diff`.

Some scripts may require MuseScore (latest stable version) to be installed and available from the command line as the command `mscore`, either in `${PATH}` or as a Bash function. Try running `mscore --help` from the command line to check if it is available. If it's not available see the section below on Adding MuseScore to `${PATH}`.

Submodules have their own requirements that must be me in order to make use of that submodule. See the submodule's README.md file for its requirements:

- [`mscore-utils-python`](https://github.com/shoogle/mscore-utils-python/)

## Download

Do a recursive clone to also download the `mscore-utils-python` submodule:

```bash
git clone --recursive https://github.com/shoogle/mscore-utils.git
cd mscore-utils
```

If you want to contribute you should fork `mscore-utils` into your own GitHub repository and clone from there instead. You should also create forks of any submodules that you plan to contribute to.

## Installation

Either add the `bin` directory to your `${PATH}`, or create a symlink to `bin/mscore-utils` somewhere that is already in `${PATH}`.

## Adding MuseScore to `${PATH}`

#### Linux and BSD

If you installed MuseScore via a package manager it may already be in `${PATH}` (you can check with `which mscore`). If you installed the AppImage or other portable version then you will need to add it to `${PATH}` manually:

```bash
mscore_path=/path/to/MuseScore/AppImage/or/mscore
ln -s "${mscore_path}" ~/bin/mscore
```

If MuseScore fails to load because it can't find its libraries try adding it as a Bash function instead.

```bash
[ -l ~/bin/mscore ] && rm ~/bin/mscore
echo "function mscore() { \"${mscore_path}\" \"\$@\" ;} && export -f mscore" >> ~/.bashrc
```

#### macOS

If you are on macOS you need to add `mscore` as a Bash function:

```bash
mscore_path="/Applications/MuseScore 2.app/Contents/MacOS/mscore"
echo "function mscore() { \"${mscore_path}\" \"\$@\" ;} && export -f mscore" >> ~/.bash_profile
```
