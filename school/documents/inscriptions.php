<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];
    if('GET_STUDENT_INSCRIPTIONS' == $action){
        
        // $login = $_POST['login'];
        $CodeEleve = $_POST['CodeEleve'];
        $db_data = array();
        $sql = "SELECT * FROM inscriptions WHERE CodeEleve = '$CodeEleve'";
        $result = mysqli_query($db,$sql);
        $count = mysqli_num_rows($result);
        
        if($count > 0){
            while($row = $result->fetch_assoc()){
                $db_data[] = $row;
            }
            echo json_encode($db_data);
        }else{
            echo json_encode("Error");
        }
        $db->close;
        return;
    }

    if('GET_STUDENT_HISTORIQUE_INSCRIPTIONS' == $action){
        
        // $login = $_POST['login'];
        $CodeEleve = $_POST['CodeEleve'];
        $NUMFAC = $_POST['NUMFAC'];

        $db_data = array();
        $sql = "SELECT * FROM historique_inscriptions WHERE CodeEleve = '$CodeEleve' AND NUMFAC = '$NUMFAC'";
        $result = mysqli_query($db,$sql);
        $count = mysqli_num_rows($result);
        
        if($count > 0){
            while($row = $result->fetch_assoc()){
                $db_data[] = $row;
            }
            echo json_encode($db_data);
        }else{
            echo json_encode("Error");
        }
        $db->close;
        return;
    }

    if('GET_ALL' == $action){
        $db_data = array();
        $sql = "SELECT * FROM inscriptions";
        $result = mysqli_query($db,$sql);
        $count = mysqli_num_rows($result);
        
        if($count > 0){
            while($row = $result->fetch_assoc()){
                $db_data[] = $row;
            }
            echo json_encode($db_data);
        }else{
            echo "Error";
        }
        $db->close;
        return;
    }
?>