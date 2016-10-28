<?php
$CMD = $argv[1];

//PDO
$PDO = new PDO("mysql:host=localhost;dbname=phpgolf",'username','passwd');
//Make output
function makeOutput($name,array $values) {
    echo "$name?";
    $first=true;
    foreach($values as $key => $value) {
        if(empty($value)) {
            continue;
        }
        $value = rawurlencode($value);
        $key = rawurlencode($key);
        if(!$first) {
            echo "&";
        }
        echo "$key=$value";
        $first = false;
    }
    echo "\n";
}
switch ($CMD) {
    //Test file
    case 'TEST':
        echo 'Valid';
        break;
    //Get commands
    case 'GET':
        $SQL = 'SELECT a.id AS attempt_id ,a.user_id,u.username,c.id AS challenge_id,c.constant,c.name AS challenge_name,c.disabled_func,c.trim_type FROM attempts AS a, challenges AS c, users AS u WHERE NOT a.locked AND c.id = a.challenge_id AND u.id = a.user_id';
        switch ($argv[2]) {
            case 'NEW':
                //Get all new attempts
                $SQL .= ' AND NOT a.executed';
            case 'ALL':
                //Get all attempts
                $result = $PDO->query($SQL);
                while(list($attempt_id,$user_id,$username,$challenge_id,$constant,$challenge_name,$disabled_func,$trim_type)=$result->fetch()) {
                    switch($trim_type) {
                        case '0':
                            $trim_type='';
                            break;
                        case '1':
                            $trim_type='RTRIM';
                            break;
                        case '2':
                            $trim_type='LTRIM';
                            break;
                        case '3':
                            $trim_type='TRIM';
                            break;
                        
                    }
                    makeOutput('attempt',array(
                                        'attempt_id'=>$attempt_id,
                                        'user_id'=>$user_id,
                                        'username'=>$username,
                                        'challenge_id'=>$challenge_id,
                                        'challenge_name'=>$challenge_name,
                                        'constant'=>$constant,
                                        'disabled_func'=>$disabled_func,
                                        'trim_type'=>$trim_type));
                }
                break;
            case 'CHALL':
                //Get all attempts on chall
                $challId = $argv[3];
                $SQL .= ' AND c.id=:cid';
                $pre = $PDO->prepare($SQL);
                $pre->execute(array(':cid'=>$argv[3]));
                while(list($attempt_id,$user_id,$username,$challenge_id,$constant,$challenge_name,$disabled_func,$trim_type)=$pre->fetch()) {
                    switch($trim_type) {
                        case '0':
                            $trim_type='';
                            break;
                        case '1':
                            $trim_type='RTRIM';
                            break;
                        case '2':
                            $trim_type='LTRIM';
                            break;
                        case '3':
                            $trim_type='TRIM';
                            break;
                        
                    }
                    makeOutput('attempt',array(
                                        'attempt_id'=>$attempt_id,
                                        'user_id'=>$user_id,
                                        'username'=>$username,
                                        'challenge_id'=>$challenge_id,
                                        'challenge_name'=>$challenge_name,
                                        'constant'=>$constant,
                                        'disabled_func'=>$disabled_func,
                                        'trim_type'=>$trim_type));
                }
                break;
            case 'ATTEMPT':
                //Get one attempts from id
                $attemptId = $argv[3];
                $SQL .= ' AND a.id=:aid';
                $pre = $PDO->prepare($SQL);
                $pre->execute(array(':aid'=>$argv[3]));
                while(list($attempt_id,$user_id,$username,$challenge_id,$constant,$challenge_name,$disabled_func,$trim_type)=$pre->fetch()) {
                    switch($trim_type) {
                        case '0':
                            $trim_type='';
                            break;
                        case '1':
                            $trim_type='RTRIM';
                            break;
                        case '2':
                            $trim_type='LTRIM';
                            break;
                        case '3':
                            $trim_type='TRIM';
                            break;
                        
                    }
                    makeOutput('attempt',array(
                                        'attempt_id'=>$attempt_id,
                                        'user_id'=>$user_id,
                                        'username'=>$username,
                                        'challenge_id'=>$challenge_id,
                                        'challenge_name'=>$challenge_name,
                                        'constant'=>$constant,
                                        'disabled_func'=>$disabled_func,
                                        'trim_type'=>$trim_type));
                }
                break;
            case 'CODE': 
                //Get code from id
                if(empty($argv[3]) || empty($argv[4]) || !is_numeric($argv[3])) {
                    echo 'ERROR';
                    exit;
                }
                $pre = $PDO->prepare('SELECT code FROM attempts WHERE id=:id');
                $pre->execute(array(':id'=>$argv[3]));
                $result = $pre->fetch();
                if(empty($result[0])) {
                    echo 'ERROR';
                    exit;
                }
                file_put_contents($argv[4],$result[0]);
                break;
            case 'ENGINE': 
                //Get enginecode from id
                if(empty($argv[3]) || empty($argv[4]) || !is_numeric($argv[3])) {
                    echo 'ERROR';
                    exit;
                }
                $pre = $PDO->prepare('SELECT engine FROM challenges WHERE id=:id');
                $pre->execute(array(':id'=>$argv[3]));
                $result = $pre->fetch();
                if(empty($result[0])) {
                    echo 'ERROR';
                    exit;
                }
                file_put_contents($argv[4],$result[0]);
                break;
        }
        break;
    case 'SAVE':
        $AttemptId = $argv[2];
        if(!is_numeric($AttemptId)) {
            echo 'ERROR';
            exit;
        }
        $Userret = $argv[4];
        $Engineret = $argv[5];
        
        if($argv[3] == 'Failed') {
            $pre = $PDO->prepare('UPDATE attempts SET executed=true, passed=false, input=:input, valid=:valid, result=:result, errors=:errors WHERE id=:id');
            $Valid = (file_exists($Engineret.'.stderr.ret')) ? file_get_contents($Engineret.'.stderr.ret') : '';
            $Input = (file_exists($Engineret.'.stdout.ret')) ? file_get_contents($Engineret.'.stdout.ret') : '';
            $Errors = (file_exists($Userret.'.err')) ? file_get_contents($Userret.'.err') : '';
            if(filesize($Userret.'.stdout.ret') > 1024*1024) {
                $Result = '--Output too big--';
            } else {
                $Result = (file_exists($Userret.'.stdout.ret')) ? file_get_contents($Userret.'.stdout.ret') : '';
            }
            $pre->execute(array(
                        ':id' => $AttemptId,
                        ':valid' => $Valid,
                        ':input' => $Input,
                        ':errors' => $Errors,
                        ':result' => $Result));
        } elseif ($argv[3] == 'Passed') {
            $pre = $PDO->prepare('UPDATE attempts SET executed=true, passed=true, input="", valid="", result="", errors="" WHERE id=:id');
            $pre->execute(array(':id' => $AttemptId));
        } else {
            echo 'ERROR';
            exit;
        }
        break;
    case 'RTRIM':
    case 'LTRIM':
    case 'TRIM':
        if(!file_exists($argv[2]) || !is_writable($argv[2]) || !is_readable($argv[2])) {
            echo 'ERROR';
            exit;
        }
        $file = file_get_contents($argv[2]);
        $file = str_replace("\r","",$file);
        if($CMD == 'RTRIM') {
            $file = rtrim($file);
        } elseif($CMD == 'LTRIM') {
            $file = ltrim($file);
        } elseif($CMD == 'TRIM') {
            $file = trim($file);
        }
        file_put_contents($argv[2],$file);
        break;
    case 'SET':
        switch($argv[2]) {
            case 'ENGINE':
                if(empty($argv[3]) || !is_numeric($argv[3]) || empty($argv[4]) || empty($argv[5])) {
                    echo 'ERROR';
                    exit;
                }
                //Update engine
                if(!$engine = file_get_contents($argv[4])) {
                    echo 'ERROR';
                    exit;
                }
                $preSelect = $PDO->prepare('SELECT engine FROM challenges WHERE id=:id');
                $preUpdate = $PDO->prepare('UPDATE challenges SET engine=:engine WHERE id=:id');
                
                //Get old
                $preSelect->execute(array(':id'=>$argv[3]));
                $Result = $preSelect->fetch();
                if(!file_put_contents($argv[5],$Result[0])) {
                    echo 'ERROR SAVING BACKUP';
                    exit;
                }
                
                //Set new
                $preUpdate->execute(array(':id'=>$argv[3],':engine' => $engine));
                
                break;
        }
        break;
}
