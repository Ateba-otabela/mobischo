<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];

    if('GET_ALL' == $action){
        $db_data = array();
        $sql = "SELECT * FROM eleves";
        $result = mysqli_query($db,$sql);
        $count = mysqli_num_rows($result);
        
        if($count > 0){
            while($row = $result->fetch_assoc()){
                $db_data = $row;
            }
            echo json_encode($db_data);
        }else{
            echo "Error";
        }
        $db->close;
        return;
    }


    if('GET_MAIN_STUDENT' == $action){
        
        $codeEleve = $_POST['codeEleve'];
        $db_data = array();
        $sql = "SELECT * FROM eleves WHERE CodeEleve = '$codeEleve'";
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


    if('GET_COURSE_STUDENTS' == $action){
        $codeClasse = $_POST['codeClasse'];
        $db_data = array();
        $sql = "SELECT * FROM eleves WHERE CodeClasse = '$codeClasse'";
        $result = mysqli_query($db, $sql);

        if($result->num_rows > 0){
            while($row = $result->fetch_assoc()){
                $db_data[] = $row;
            }
            echo json_encode($db_data);
        }else{
            echo "error";
        }
        $db->close();
        return;
    }


    if('GET_PARENT_STUDENTS' == $action){
        $code = $_POST['code'];
        $db_data = array();
        $sql = "SELECT * FROM eleves WHERE code = 'ENS1000004'";
        $result = mysqli_query($db, $sql);

        if($result->num_rows > 0){
            while($row = $result->fetch_assoc()){
                $db_data[] = $row;
            }
            echo json_encode($db_data);
        }else{
            echo "error";
        }
        $db->close();
        return;
    }

?>