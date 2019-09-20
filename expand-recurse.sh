#!/bin/sh

STR_SUFFIX="_expanded" # 出力先が未指定の場合に付与する suffix
INT_TAB_LENGTH=4       # expand コマンドの `-t` オプションに指定するタブ幅
bool_force_delete=1    # 出力先がすでに存在している場合に強制的に削除するかどうか(default:False)

func_show_usage() {
    echo "Usage: $0 [-o dir] [-f] item ..."
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

    str_out_path_abs=$1 # 確認対象(フルパス)
    str_in_path_abs=$2  # 確認対象の生成元(フルパス)

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

    if [ $bool_check_delete -eq 0 ] ; then # 出力先が存在する

        #todo 消してはいけないパスかどうか確認

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

        if [ $? -ne 0 ] ; then # 削除失敗の場合
            exit 1 # 異常終了
        fi
    fi
}

output_path_specified=""

while getopts o:fh OPT
do
    case $OPT in
        o ) output_path_specified=$OPTARG
            ;;
        f ) bool_force_delete=0 # True を設定
            ;;
        h ) func_show_usage # ヘルプ表示の場合
            exit 0 # 正常終了
            ;;
        \?) func_show_usage # Unkown option の場合
            exit 1 # 異常終了
            ;;
    esac
done

shift $(($OPTIND - 1)) # 引数リストのシフト

if [ -n "$output_path_specified" ] ; then # 出力先が指定されていた場合

    if [ $# -gt 1 ] ; then # 処理対象が 2つ以上ある場合
        echo "If output specified (using `-o` option), number of target item should be only one."
        exit 1 # エラー終了
    fi
fi

# 引数を順次処理するループ
for str_arg in "$@"
do

    if [ ! -e "$str_arg" ] ; then # 処理対象が存在しない場合
        echo
        echo "[warning] $str_arg"
        echo "[warning] No such file or directory"
    
    else # 処理対象が存在する場合

        str_arg_abs=$(readlink -f "$str_arg") #フルパスの取得

        if [ -f "$str_arg_abs" ] ; then # 処理対象はファイルの場合

            if [ -n "$output_path_specified" ] ; then # 出力先指定がある場合
                str_out_file_path=$(readlink -f "$output_path_specified") # 指定パスのフルパスを採用

            else # 出力先指定がない場合
                
                str_arg_parent=$(dirname "$str_arg_abs") #親パスの取得
                str_arg_base=$(basename "$str_arg") # ファイル名を取得
                str_arg_base_no_ext=${str_arg_base%.*} # ファイル名(拡張子なし)を取得
                str_arg_base_ext=${str_arg_base#${str_arg_base_no_ext}} #拡張子名(`.`つき)を取得
                
                if [ -z "$str_arg_base_no_ext" ] ; then # `.` 始まりのファイル名の時 ( `.gitignore` 等)
                    str_arg_base_no_ext="$str_arg_base_ext"
                    str_arg_base_ext=""
            
                fi

                # suffix 付きパス名の生成
                str_out_file_path="$str_arg_parent/$str_arg_base_no_ext$STR_SUFFIX$str_arg_base_ext"

                #todo ファイル 作成失敗時のハンドリング
            fi

            # 生成先ファイルの存在チェック
            func_check_delete "$str_out_file_path" "$str_arg_abs"

            # expand
            expand -t $INT_TAB_LENGTH "$str_arg_abs" > "$str_out_file_path"

        else # 処理対象はディレクトリの場合

            if [ -n "$output_path_specified" ] ; then # 出力先指定がある場合
                str_out_file_path=$(readlink -f "$output_path_specified") # 指定パスのフルパスを採用

            else # 出力先指定がない場合

                # suffix 付きパス名の生成
                str_out_file_path="$str_arg_abs$STR_SUFFIX"
            fi

            # 生成先ファイルの存在チェック
            func_check_delete "$str_out_file_path" "$str_arg_abs"

            strarr_files=$(cd $str_arg_abs && find * -type f) # すべてのファイルリストを取得

            for str_file in $strarr_files; do

                str_file_abs="$str_arg_abs/$str_file" #sourceフルパスの取得
                str_out_file_abs="$str_out_file_path/$str_file" #outフルパスの取得
                str_out_file_abs_parent=$(dirname "$str_out_file_abs") #outフルパスの親パス取得

                # expand
                mkdir -p "$str_out_file_abs_parent" # 出力先ファイル配置用ディレクトリの作成
                expand -t $INT_TAB_LENGTH "$str_file_abs" > "$str_out_file_abs"

                #todo ファイル or ディレクトリ作成失敗時のハンドリング

            done

        fi
    fi

done
