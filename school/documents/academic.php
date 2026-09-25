<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];
    if('GET_ALL_YEARS' == $action){
        
        // $codeEnseignement = $_POST['codeEnseignement'];
        $db_data = array();
        $sql = "SELECT * FROM annees";
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

    if('GET_MAIN_YEAR' == $action){
        
        $codeAnnee = $_POST['codeAnnee'];
        $db_data = array();
        $sql = "SELECT * FROM annees WHERE CodeAnnee = '$codeAnnee'";
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

    if('GET_MAIN_SEQUENCE' == $action){
        $codeEvaluation = $_POST['codeEvaluation'];
        $db_data = array();
        $sql = "SELECT * FROM sequence_evaluations WHERE CodeEvaluation = '$codeEvaluation'";
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


    if('GET_ALL_SEQUENCES' == $action){
        $db_data = array();
        $sql = "SELECT * FROM sequence_evaluations";
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


    if('CREATE_TABLE_CONVOCATION' == $action){
        $db_data = array();
        $sql = "CREATE TABLE IF NOT EXISTS convocations (
            CodeConvocation INT(100) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            CodeEnseignant VARCHAR(100),
            CodeEleve VARCHAR(100),
            motif VARCHAR(100),
            CodeEnseignement VARCHAR(100),
            CodeMatiere VARCHAR(100),
            dateEnreg VARCHAR(100)
        )";
        $result = mysqli_query($db,$sql);
        // $count = mysqli_num_rows($result);
        
        if($result){
            echo json_encode('success');
        }else{
            echo "Error";
        }
        $db->close;
        return;
    }

    if('INSERT_CONVOCATION' == $action){
        
        $CodeEnseignant = $_POST['CodeEnseignant'];
        $CodeEleve = $_POST['CodeEleve'];
        $motif = $_POST['motif'];
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $CodeMatiere = $_POST['CodeMatiere'];
        $dateEnreg = $_POST['dateEnreg'];

        $db_data = array();
        $sql = "INSERT INTO convocations (CodeEnseignant, CodeEleve, motif, CodeEnseignement, CodeMatiere, dateEnreg) VALUES ('$CodeEnseignant','$CodeEleve','$motif','$CodeEnseignement','$CodeMatiere','$dateEnreg');";
        $result = mysqli_query($db,$sql);
        // $count = mysqli_num_rows($result);
        
        if($result){
            echo json_encode('success');
        }else{
            echo "Error";
        }
        $db->close;
        return;
    }

?>