<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];
    if('GET_TEACHER_COURSES' == $action){
        
        $teacher_code = $_POST['teacher_code'];
        $db_data = array();
        $sql = "SELECT * FROM enseignements WHERE code = '$teacher_code'";
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

    if('GET_CLASS_COURSES' == $action){
        
        $CodeClasse = $_POST['CodeClasse'];
        $db_data = array();
        $sql = "SELECT * FROM enseignements WHERE CodeClasse = '$CodeClasse'";
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

    if('GET_MAIN_COURSE' == $action){
        
        $code_matiere = $_POST['code_matiere'];
        $db_data = array();
        $sql = "SELECT * FROM matieres WHERE CodeMatiere = '$code_matiere'";
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

    if('GET_MAIN_CLASS' == $action){
        
        $code_classe = $_POST['code_classe'];
        $db_data = array();
        $sql = "SELECT * FROM classes WHERE CodeClasse = '$code_classe'";
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
        $sql = "SELECT * FROM enseignements";
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