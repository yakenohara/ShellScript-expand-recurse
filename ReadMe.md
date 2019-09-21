Run the `expand` command recursively.

# Installation

Place `expand-recurse.sh` anywhere you like.

# Usage

```
$ expand-recurse.sh [-o output] [-f] [-h] input ...
```

You can try `expand-recurse.sh example` command after pulling this repository.

## Required argment

 - input ...  
   File(s) or directory(s) to expand.

## Options

 - `-o`  
   Output path.
 - `-f`  
   If output path is already exists, that path will be deleted before prosess without asking on prompt.
 - `-h`  
   Show usage of this script.

## Change settings

Following parameters can be change by editing `expand-recurse.sh` .

 - STR_SUFFIX="_expanded"  
   suffix for output path
 - INT_TAB_LENGTH=4  
   `-t` option value of `expand` comand
 - STRARR_EXTENSIONS=(".c" ".h")  
    File extensions to expand. Files not in this list will be only copied.

# Limitation

 - Hidden path will be not processed  
  If directory is specified, hidden file and directory placed under that specified directory will be not processed.
