#!/bin/sh

# <License>------------------------------------------------------------

#  Copyright (c) 2019 Shinnosuke Yakenohara

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -----------------------------------------------------------</License>


# <Settings>-----------------------------------------------------------------
STR_SUFFIX="_expanded" # suffix for output path
INT_TAB_LENGTH=4       # `-t` option value of `expand` comand
STRARR_EXTENSIONS=(    # File extensions to expand.
    ".c"               # Files not in this list will be only copied.
    ".h"
)
# ----------------------------------------------------------------</Settings>

bool_force_delete=1    # 出力先がすでに存在している場合に強制的に削除するかどうか(default:False)

func_show_usage(){
cat<<'EOF'

# Usage

```
$ expand-recurse.sh [-o output] [-f] [-h] input ...
```

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

# Limitation

 - Hidden path will be not processed  
  If directory is specified, hidden file and directory placed under that specified directory will be not processed.

EOF
}

# yes or no 取得
bool_yn=1
func_yn(){
    read answer
    case $answer in
        y)
            bool_yn=0 # True
            ;;
        n)
            bool_yn=1 # False
            ;;
        *)
            echo -e "Please answer y or n."
            func_yn
            ;;
    esac
}

# 生成先パスの存在チェック
func_check_delete(){

    str_out_path_abs="$1" # 確認対象(フルパス)
    str_in_path_abs="$2"  # 確認対象の生成元(フルパス)

    bool_check_delete=1
    str_file_or_dir=""

     # 処理対象がファイル && 出力先ファイルが存在する
    if [ -f "$str_in_path_abs" ] && [ -f "$str_out_path_abs" ] ; then
        bool_check_delete=0
        str_file_or_dir="file"
    
    # 処理対象がディレクトリ && 出力先ディレクトリが存在する
    elif [ -d "$str_in_path_abs" ] && [ -d "$str_out_path_abs" ] ; then
        bool_check_delete=0
        str_file_or_dir="directory"

    fi

    if [ $bool_check_delete -eq 0 ] ; then # 出力先が存在する場合

        # 消してはいけないパスかどうか確認
        if [ "$str_out_path_abs" = "$str_in_path_abs" ] ; then # 入出力が同じ場合
            echo 
            echo "[error] Specified input and output $str_file_or_dir (interpreted as follow) are the same." 1>&2
            echo "[error] input  $str_file_or_dir:$str_in_path_abs" 1>&2
            echo "[error] output $str_file_or_dir:$str_out_path_abs" 1>&2
            exit 1 # 異常終了
        fi
        if [ -f "$str_out_path_abs" ] ; then # 出力先はファイルの場合
            if [ "$str_out_path_abs" = "$str_me_path_abs" ] ; then # 出力先ファイルがこのスクリプトの場合
                echo 
                echo "[error] Specified output file (interpreted as follow) and path of this script file are the same." 1>&2
                echo "[error] Specified output path:$str_out_path_abs" 1>&2
                echo "[error] This script file path:$str_me_path_abs" 1>&2
                exit 1 # 異常終了
            fi
        else # 出力先はディレクトリの場合
            str_matched=${str_me_path_abs%${str_me_path_abs#$str_out_path_abs}}
            if [ "$str_out_path_abs" = "$str_matched" ] ; then # 出力先ディレクトリにこのスクリプトが含まれる場合
                echo 
                echo "[error] Specified output directory path (interpreted as follow) is already exists and" 1>&2
                echo "[error] that directory includes this script file." 1>&2
                echo "[error] Specified output path:$str_out_path_abs" 1>&2
                echo "[error] This script file path:$str_me_path_abs" 1>&2
                exit 1 # 異常終了
            fi
        fi

        # 出力先がすでに存在している場合に強制的に削除するオプションが指定されていない場合
        if [ $bool_force_delete -ne 0 ] ; then

            # 削除確認メッセージ
            echo 
            echo "[warning] Specified output $str_file_or_dir (interpreted as follow) is already exists."
            echo "[warning] $str_out_path_abs"
            echo "[warning] Delete this $str_file_or_dir and proceed? (y/n)"

            func_yn # yes / no 取得
            
            if [ $bool_yn -ne 0 ] ; then # "削除しない" を選択の場合
                exit 0 # 終了
            fi
        fi

        rm -r -f -v "$str_out_path_abs" # すでに存在する出力先を削除

        echo 

        if [ $? -ne 0 ] ; then # 削除失敗の場合
            exit 1 # 異常終了
        fi
    fi
}

# ファイル名(拡張子なし)と拡張子に分割する
str_absolute_path_parent=""
str_absolute_path_base=""
str_absolute_path_no_ext=""
str_absolute_path_ext=""
func_parse_file_ext(){

    str_absolute_path="$1"

    # initialize
    str_absolute_path_parent=""
    str_absolute_path_base=""
    str_absolute_path_no_ext=""
    str_absolute_path_ext=""

    str_absolute_path_parent=$(dirname "$str_absolute_path") #親パスの取得
    str_absolute_path_base=$(basename "$str_absolute_path") # ファイル名を取得
    str_absolute_path_no_ext=${str_absolute_path_base%.*} # ファイル名(拡張子なし)を取得
    str_absolute_path_ext=${str_absolute_path_base#${str_absolute_path_no_ext}} #拡張子名(`.`つき)を取得
    
    # 空文字の場合 (= `.` 始まりのファイル名の時 ( `.gitignore` 等))
    if [ -z "$str_absolute_path_no_ext" ] ; then
        str_absolute_path_no_ext="$str_absolute_path_ext"
        str_absolute_path_ext=""
    fi
}

# expand 対象のファイル拡張子リストに該当するかどうかチェックする
bool_in_list=1
func_check_target_is_in_list(){

    str_to_check_path="$1"
    bool_in_list=1

    func_parse_file_ext "$str_to_check_path" # 拡張子取得
    
    for ((int_index = 0; int_index < ${#STRARR_EXTENSIONS[@]}; int_index++))
    do
        if [ "${STRARR_EXTENSIONS[$int_index]}" = "$str_absolute_path_ext" ] ; then
            bool_in_list=0
            break
        fi
    done
}

str_user_specified_out_path=""
str_me_path_abs=$(readlink -f "$0")

# Option parsing
while getopts o:fh OPT
do
    case $OPT in
        o ) str_user_specified_out_path=$OPTARG
            ;;
        f ) bool_force_delete=0 # True を設定
            ;;
        h ) func_show_usage # ヘルプ表示
            exit 0 # 正常終了
            ;;
        \?) echo "[error] Unkown option specified." 1>&2 # Unkown option の場合
            func_show_usage # ヘルプ表示
            exit 1 # 異常終了
            ;;
    esac
done

shift $(($OPTIND - 1)) # 引数リストのシフト

if [ -n "$str_user_specified_out_path" ] ; then # 出力先が指定されていた場合

    if [ $# -gt 1 ] ; then # 処理対象が 2つ以上ある場合
        echo "[error] If output specified (using `-o` option), number of input item should be only one." 1>&2
        exit 1 # エラー終了
    fi
    
    # ワイルドカードを指定していないかどうかチェック
    echo "$str_user_specified_out_path" | grep "\*" > /dev/null
    if [ $? -eq 0 ] ; then # ワイルドカードを指定している場合
        echo "[error] Wild card \`*\` cannot specify as output." 1>&2
        exit 1 # 異常終了
    fi
fi

if [ $# -eq 0 ] ; then # 処理対象の指定がない場合
    echo "[error] input item not specified" 1>&2
    exit 1 # 異常終了
fi

echo
echo "Prosessing..."
echo

# 引数を順次処理するループ
for str_arg in "$@"
do

    if [ ! -e "$str_arg" ] ; then # 処理対象が存在しない場合
        echo
        echo "[error] $str_arg" 1>&2
        echo "[error] No such file or directory" 1>&2
    
    else # 処理対象が存在する場合

        str_arg_abs=$(readlink -f "$str_arg") #フルパスの取得

        echo "$str_arg_abs"

        if [ -f "$str_arg_abs" ] ; then # 処理対象はファイルの場合

            if [ -n "$str_user_specified_out_path" ] ; then # 空文字ではない(=出力先指定がある場合)
                str_out_file_path_abs=$(readlink -f "$str_user_specified_out_path") # 指定パスのフルパスを採用
                
            else # 出力先指定がない場合

                func_parse_file_ext "$str_arg_abs" # ファイル名(拡張子なし)と拡張子に分割

                # suffix 付きパス名の生成
                str_out_file_path_abs="$str_absolute_path_parent/$str_absolute_path_no_ext$STR_SUFFIX$str_absolute_path_ext"

            fi

            # 生成先ファイルの存在チェック
            func_check_delete "$str_out_file_path_abs" "$str_arg_abs"

            mkdir -p "$(dirname "$str_out_file_path_abs")" # 出力先ファイル配置用ディレクトリの作成

            # expand 対象のファイル拡張子リストに該当するかどうかチェック
            func_check_target_is_in_list "$str_out_file_path_abs"

            if [ $bool_in_list -eq 0 ] ; then # 拡張子リストに該当する場合
                expand -t $INT_TAB_LENGTH "$str_arg_abs" > "$str_out_file_path_abs" # expand
                donecmd="expand -t $INT_TAB_LENGTH $str_arg_abs > $str_out_file_path_abs"

            else # 拡張子リストに該当しない場合
                cp "$str_arg_abs" "$str_out_file_path_abs" # copy
                donecmd="cp $str_arg_abs $str_out_file_path_abs"
            fi

            # expand
            expand -t $INT_TAB_LENGTH "$str_arg_abs" > "$str_out_file_path_abs"

            if [ $? -ne 0 ] ; then # expand コマンド失敗の場合
                echo
                echo "[error] Following command exists with a failure" 1>&2
                echo "[error] $donecmd" 1>&2
                # exit 1 # 異常終了
            fi

        else # 処理対象はディレクトリの場合

            if [ -n "$str_user_specified_out_path" ] ; then # 空文字ではない(=出力先指定がある場合)
                str_out_dir_path_abs=$(readlink -f "$str_user_specified_out_path") # 指定パスのフルパスを採用

            else # 出力先指定がない場合

                str_out_dir_path_abs="$str_arg_abs$STR_SUFFIX" # suffix 付きパス名の生成
            fi

            # 生成先ファイルの存在チェック
            func_check_delete "$str_out_dir_path_abs" "$str_arg_abs"

            strarr_files_cmd=$(cd $str_arg_abs && find * -type f) # すべてのファイルリストを取得

            # スペースを含むパス名対応
            IFS_BACK="$IFS" # IFS 設定をバックアップ
            IFS=$'\n'       # IFS 設定を `\n` に変更
            strarr_files=() # 配列定義
            for strarr_files_cmd_elem in $strarr_files_cmd
            do
                strarr_files+=("$strarr_files_cmd_elem") # 配列に追加
            done
            IFS="$IFS_BACK" # IFS 設定をもとに戻す
            
            # 
            for ((int_index_of_strarr_files=0 ; int_index_of_strarr_files < ${#strarr_files[@]}; int_index_of_strarr_files++))
            do

                str_file="${strarr_files[$int_index_of_strarr_files]}"

                str_file_abs="$str_arg_abs/$str_file" #sourceフルパスの取得
                str_out_file_abs="$str_out_dir_path_abs/$str_file" #outフルパスの取得
                str_out_file_abs_parent=$(dirname "$str_out_file_abs") #outフルパスの親パス取得

                echo "$str_file_abs"

                mkdir -p "$str_out_file_abs_parent" # 出力先ファイル配置用ディレクトリの作成

                # expand 対象のファイル拡張子リストに該当するかどうかチェック
                func_check_target_is_in_list "$str_file_abs"

                if [ $bool_in_list -eq 0 ] ; then # 拡張子リストに該当する場合
                    expand -t $INT_TAB_LENGTH "$str_file_abs" > "$str_out_file_abs" # expand
                    donecmd="expand -t $INT_TAB_LENGTH $str_file_abs > $str_out_file_abs"

                else # 拡張子リストに該当しない場合
                    cp "$str_file_abs" "$str_out_file_abs" # copy
                    donecmd="cp $str_file_abs $str_out_file_abs"
                fi

                if [ $? -ne 0 ] ; then # expand コマンド失敗の場合
                    echo
                    echo "[error] Following command exists with a failure" 1>&2
                    echo "[error] $donecmd" 1>&2
                    exit 1 # 異常終了
                fi

            done

        fi
    fi

done

echo
echo "Done!"
