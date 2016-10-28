#!/bin/bash
ROOT='/home/phpgolf/validation';
# runPHP "$file" "$secure" "$return" "$disable_functions"
. $ROOT/runphp.sh;

FILE=$1
DATE=$(date +"%Y.%m.%d-%H:%M:%S");
TMP="/tmp/phpgolf-$DATE";
RETURN=$TMP/engine;
mkdir $TMP;
FILEnew="$TMP/${FILE%.*}-1.php";
echo -n "<?php define('RUN',1);?>" >>"$FILEnew";
cat "$FILE" >>"$FILEnew";
runPHP "$FILEnew" false "$RETURN";

chmod a+rw "$return_stdout" 2>/dev/null;
chmod a+rw "$return_stderr" 2>/dev/null;
chmod a+rw "$return_error" 2>/dev/null;

echo -e "------ stdout ------\n";
cat "$return_stdout";
echo -e "\n\n------ stderr ------\n";
cat "$return_stderr";
echo -e "\n\n------ error ------\n";
cat "$return_error";

rm -rf "$TMP";
