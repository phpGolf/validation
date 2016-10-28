#!/bin/bash
ROOT='/home/phpgolf/validation';
PHP='/home/phpgolf/php-5.3.3-normal/bin/php';
PHPsecure="/home/phpgolf/php-5.3.3-normal/bin/php";


DISABLE_FUNC=$(cat $ROOT/disabled_func | tr '\n' ',' | sed 's/,$//');
DISABLE_CLASS=$(cat $ROOT/disabled_class | tr '\n' ',' | sed 's/,$//');
DATE=$(date +"%Y.%m.%d-%H:%M:%S");

# Test paths
#Check PHP
if [ ! -x "$PHP" ]; then
    echo ' [X] Did not find PHP ('$PHP')';
    exit 1;
fi
if [[ $($PHP -r "echo 'Valid';") != 'Valid' ]]; then
    echo ' [X] Did not find valid PHP ('$PHP')';
    exit 1;
fi


#Check secure php
if [ ! -x "$PHPsecure" ]; then
    echo ' [X] Did not find secure PHP ('$PHPsecure')';
    exit 1;
fi

if [[ $($PHPsecure -r "echo 'Valid';") != 'Valid' ]]; then
    echo ' [X] Did not find valid secure PHP ('$PHPsecure')';
    exit 1;
fi




# runPHP "$file" "$secure" "$return" "$disable_functions"
runPHP() {
    return_stdout="$3.stdout.ret";
    return_stderr="$3.stderr.ret";
    return_error="$3.err";
    if [[ $2 == false ]]; then
        $PHP -c "$ROOT/php.ini" -d "memory_limit=10M" -d "error_log=$return_error" "$1" 1>$return_stdout 2>$return_stderr &
        pid=$!;
    else
        disable=$DISABLE_FUNC;
        if [[ "$4" != '' ]]; then
            disable="$disable,$4";
        fi
        $PHPsecure -c "$ROOT/php.ini" -d "error_log=$return_error" -d "disable_classes='$DISABLE_CLASS'" -d "disable_functions='$disable'" "$1" 1>$return_stdout &
        pid=$!;
    fi
    count=0;
    kill -0 $pid 2>/dev/null;
    kill=$?;
    while [ $kill = "0" ]; do
        if [ $count == 10 ]; then
            kill -9 $pid &>/dev/null;
            echo "["`date +"%d-%b-%Y %T"`"] -- Script was killed --">>"$return_error";
        fi
        sleep 1
        count=$(($count+1));
        kill -0 $pid 2>/dev/null;
        kill=$?;
    done
    if [ -a "$return_error" ]; then
        return 1;
    fi
    return 0;
}
