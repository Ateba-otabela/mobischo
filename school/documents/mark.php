<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];
    if('GET_COURSE_MARKS' == $action){
        
        $codeEnseignement = $_POST['codeEnseignement'];
        $db_data = array();
        $sql = "SELECT * FROM notes WHERE CodeEnseignement = '$codeEnseignement'";
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

    if('GET_STUDENT_MARKS' == $action){
        
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $CodeEleve = $_POST['CodeEleve'];

        $db_data = array();
        $sql = "SELECT * FROM notes WHERE CodeEnseignement = '$CodeEnseignement' AND CodeEleve = '$CodeEleve'";
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

    
    if('GET_SORTED_STUDENT_MARKS' == $action){
        $codeEnseignement = $_POST['codeEnseignement'];
        $codeEleve = $_POST['codeEleve'];
        $codeAnnee = $_POST['codeAnnee'];
        $codeEvaluation = $_POST['codeEvaluation'];

        $db_data = array();
        // $sql = "SELECT * FROM notes";
        $sql = "SELECT * FROM notes WHERE CodeEleve = '$codeEleve' AND CodeEnseignement = '$codeEnseignement' AND CodeAnnee = '$codeAnnee' AND CodeEvaluation = '$codeEvaluation'";
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

    if('GET_SORTED_COURSE_MARKS' == $action){
        $codeEnseignement = $_POST['codeEnseignement'];
        $codeAnnee = $_POST['codeAnnee'];
        $sequenceEvaluation = $_POST['sequenceEvaluation'];

        $db_data = array();
        $sql = "SELECT * FROM notes WHERE CodeEnseignement = '$codeEnseignement' AND CodeAnnee = '$codeAnnee' AND CodeEvaluation = '$sequenceEvaluation'";
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
        $sql = "SELECT * FROM notes";
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