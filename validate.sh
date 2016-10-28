#!/bin/bash
# Config
ROOT='/home/phpgolf/validation';
PHP='/usr/bin/php5';
HELPER=$ROOT'/helper.php';
HELPER_CMD="$PHP -f ";
COMMON="$ROOT/common_settings.php";
DATE=$(date +"%Y.%m.%d-%H:%M:%S");
Passed=0;
Failed=0;

PID="$ROOT/validate.pid";
# TMP folder
TMP="/tmp/phpgolf-$DATE";

#Memcache
mem_host='localhost';
mem_port='11211';
keys='Right ';

# PID-file
if [ -f $PID ] && [ "$1" != "ALL" ]; then
    kill -0 $(cat $PID) 2>/dev/null;
    if [[ $? == 0 ]]; then
        if [[ "$CRON" != 'running' ]]; then
            echo -e "The is an validate session running!\nIf this is not the case, please delete $PID";
        fi
        exit;
    fi
fi
if [ "$1" != "ALL" ] && [[ "$1" != [0-9]* ]] && [[ "$1" != "-a" ]]; then
    echo $$ >$PID
fi
mkdir $TMP;

# Trap kill
trap exiting 1 2 3 6
exiting () {
    rm $PID 2>/dev/null;
    rm -r "$TMP" 2>/dev/null;
    echo -e "\n\nI WAS KILLED!!!";
    if [ "$Failed" != "0" ] || [ "$Passed" != "0" ]; then
        echo 'Date: '`date`;
        echo 'Failed:' $Failed;
        echo 'Passed:' $Passed;
        echo
        #Flush memcahce
        clearMem;
    fi
    exit $1;

}

#memcache
clearMem () {
    for key in $keys
    do
        flush="$flush\n$key";
    done
    echo -e "flush_all\nquit" | nc localhost 11211 >/dev/null
}

#urldecode
urldecode () {
    decoded=$(echo "${!1}" | sed -e's/%\([0-9A-F][0-9A-F]\)/\\\\\x\1/g' | xargs echo -ne);
    eval "$1='$decoded'";
}

# Test paths
#Check PHP
if [ ! -x "$PHP" ]; then
    echo ' [X] Did not find PHP ('$PHP')';
    exiting 1;
fi
if [[ $($PHP -r "echo 'Valid';") != 'Valid' ]]; then
    echo ' [X] Did not find valid PHP ('$PHP')';
    exiting 1;
fi



#Check helper file
if [ ! -f "$HELPER" ]; then
    echo ' [X] Did not find helper file ('$HELPER')';
    exiting 1;
fi
if [[ $($HELPER_CMD $HELPER TEST) != 'Valid' ]]; then
    echo ' [X] Helper program is invalid ('$HELPER')';
    exiting 1;
fi

#Check common settings file
if [ ! -f "$COMMON" ]; then
    echo ' [X] Did not find common settings ('$COMMON')';
    exit 1;
fi

Cmd="$HELPER_CMD $HELPER";
# Find type of run
if [ "$1" == "ALL" ]; then
    GetCmd="$HELPER_CMD $HELPER GET ALL";
elif [[ "$1" == [0-9]* ]]; then
    GetCmd="$HELPER_CMD $HELPER GET CHALL $1";
elif [[ "$1" == "-a" ]]; then
    if [[ "$2" == [0-9]* ]]; then
        GetCmd="$HELPER_CMD $HELPER GET ATTEMPT $2";
    else
        echo ' [X] Missing attempt id';
        exit 1;
    fi
elif [[ "$1" == "-h" ]]; then
echo "phpGolf attempt validation script";
echo;
echo "Arguments:";
echo "---------------------------------------------------------------------------";
echo "./validation.sh -h                Show this help message.";
echo "./validation.sh                   Validate new attempts.";
echo "./validation.sh ALL               Validate ALL attempts.*";
echo "./validation.sh <cid>             Validate all attempts on challenge.*";
echo "./validation.sh -a <aid>          Validate one attempts.";
echo;
echo "Constants sent to engine script:";
echo "---------------------------------------------------------------------------";
echo "RUN                               Current run number under testing attempts";
echo "INPUT                             Varible sent from the commandline";
echo;
echo "To send a string to the engine, place the string as the third argument.";
echo "* Please do this in a seperate screen session.";
exit 0;
else
    GetCmd="$HELPER_CMD $HELPER GET NEW";
fi

# runPHP "$file" "$secure" "$return" "$disable_functions"
. $ROOT/runphp.sh;



# Get list
for attempt in $($GetCmd);
do
    unset constant;
    unset disabled_func_dec;
    #Parse info
    info=$(echo $attempt | sed 's/[a-z]*?//' | tr '&' ' ');
    for line in $info;
    do
        key=$(echo $line | tr '=' ' ' | awk '{print $1}');
        value=$(echo $line | tr '=' ' ' | awk '{print $2}');
        unset $key;
        declare $key="$value";
        urldecode key;
        urldecode value;
        declare "$key"_dec="$value";
    done
    Usercode="$TMP/$username-$challenge_name-$attempt_id-usercode.php";
    #Get code
    if [[ "$($Cmd GET CODE $attempt_id "$Usercode")" == 'ERROR' ]]; then
        echo ' [X] Error when getting usercode';
        echo " [i] Attempt id = $attempt_id";
        exiting 1;
    fi
    
    Enginecode="$TMP/$challenge_name-engine.php";
    #Get engine
    if [ ! -f "$Enginecode" ]; then
        if [[ "$($Cmd GET ENGINE $challenge_id "$Enginecode")" == 'ERROR' ]]; then
            echo ' [X] Error when getting enginecode';
            echo " [i] Challenge_id = $challenge_id";
            exiting 1;
        fi
    fi
    if [ ! -n "$constant" ]; then
        Runs=1;
    else
        Runs=10;
    fi
    echo " [i] Running attempt $attempt_id on challenge $challenge_name_dec uploaded by $username_dec";
    echo " [i] Running $Runs times"
    fail=0;
    for run in $(seq $Runs)
    do
        echo -n " [i] Run number $run ";
        #Run enginecode
        Engineret="$TMP/$username-$challenge_name-$attempt_id-engine-return-$run";
        EnginecodeNew="${Enginecode%.*}-$attempt_id-enginecode-$run.php";
        echo -n "<?php define('RUN','$run');?>" >"$EnginecodeNew";
        if [[ "$3" != "" ]]; then
            echo -n "<?php define('INPUT','$3');?>" >>"$EnginecodeNew";
        fi
        cat "$Enginecode" >>"$EnginecodeNew";
        runPHP "$EnginecodeNew" false "$Engineret"
        if [ -f "$Engineret.err" ]; then
            echo " [X] Errors when running enginecode";
            echo " [i] Challenge id = $challenge_id";
            echo " [i] Errors:";
            cat "$Engineret.err";
            exiting 1;
        fi
        #Run usercode
        Userret="$TMP/$username-$challenge_name-$attempt_id-user-return-$run";
        #Check for constant
        UsercodeNew="${Usercode%.*}-$run.php";
        #Add common settings
        cat $COMMON >$UsercodeNew;
        if [ -n "$constant" ]; then
            echo -n "<?php define('$constant','">>$UsercodeNew;
            cat "$Engineret.stdout.ret" >>$UsercodeNew;
            echo "');?>" >>$UsercodeNew
        fi
        cat $Usercode >>$UsercodeNew;
        runPHP "$UsercodeNew" true "$Userret" "$disabled_func_dec";
        if [ -f "$Userret.err" ]; then
            echo " Failed (Error in code)";
            fail=1;
            break;
        fi
        #trim
        if [[ "$trim_type" != 0 ]]; then
            $($Cmd "$trim_type" "$Userret.stdout.ret");
            $($Cmd "$trim_type" "$Engineret.stderr.ret");
        fi
        diff "$Userret.stdout.ret" "$Engineret.stderr.ret" &>/dev/null;
        if [ "$?" -gt 0 ]; then
            echo " Failed";
            fail=1;
            break;
        else
            echo " Passed";
        fi
    done
    if [[ "$fail" == 1 ]]; then #Failed code
        echo ' [!] Attempt failed';
        $($Cmd SAVE $attempt_id Failed "$Userret" "$Engineret");
        Failed=$(($Failed+1));
    else #Passed code
        echo ' [!] Attempt passed';
        $($Cmd SAVE $attempt_id Passed "$Userret" "$Engineret");
        Passed=$(($Passed+1));
    fi
    echo;
    # Memcache keys
    key=" Right_Challenge_$challenge_id";
    echo $keys | grep "$key" &>/dev/null
    if [ $? -gt 0 ]; then
        keys="$keys $key";
    fi
    key=" Challenge_$challenge_id";
    echo $keys | grep "$key" &>/dev/null
    if [ $? -gt 0 ]; then
        keys="$keys $key";
    fi
done



# Remove TMP dir
rm -rf "$TMP" 2>/dev/null;
# Remove PID file
rm -f $PID 2>/dev/null

if [ "$Failed" != "0" ] || [ "$Passed" != "0" ]; then
    echo 'Date: '`date`;
    echo 'Failed:' $Failed;
    echo 'Passed:' $Passed;
    echo
    #Flush memcahce
    clearMem;
fi
