<?php
function errorHandler($errno, $errstr, $errfile, $errline) {
    $NAME[1]="E_ERROR";
    $NAME[2]="E_WARNING";
    $NAME[4]="E_PARSE";
    $NAME[8]="E_NOTICE";
    $NAME[2048]="E_STRICT";
    switch($errno) {
        case E_NOTICE:
        case E_DEPRECATED:
        case E_STRICT:
            break;
        default:
            if(error_reporting() == 0 && $errno == E_WARNING) {
                return false;
            }
                $errorName = ($NAME[$errno]) ? $NAME[$errno] : $errno;
                echo "phpGolf Fatal error ($errorName):  $errstr in $errfile on line $errline\n";
                exit;
            break;
    }
}
set_error_handler('errorHandler');
unset($_ENV);
unset($_SERVER);
?>
