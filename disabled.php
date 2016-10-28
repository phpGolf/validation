<?php

$file = file('disabled_func');
$funcs = get_defined_functions();

foreach($file as $function) {
    if(!in_array(substr($function,0,-1),$funcs['internal'])) {
        echo $function;
    }
}
