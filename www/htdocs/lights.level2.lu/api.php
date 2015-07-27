<?php

  if ( isset( $_GET['area'] ) ) {
    $area = (string) $_GET['area'];
    if ( isset( $_GET['status'] ) ) {
      $status = (string) $_GET['status'];
      if ( strtolower( $area ) != 'all' ) {
        echo json_encode( array ( "level2" => "happy hacking ;)" ) );
        $command = 'lightcommander ' . $area . ' ' . $status;
        exec ( escapeshellcmd($command) );
      }
    }
  }
