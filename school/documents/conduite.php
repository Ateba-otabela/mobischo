<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];
    if('ADD_CONDUITE' == $action){
        
        $DateEnreg = $_POST['DateEnreg'];
        $CodeEleve = $_POST['CodeEleve'];
        $Nombre = $_POST['Nombre'];
        $CodeEtatCond = '';
        $CodeClasse = $_POST['CodeClasse'];
        $CodeAnnee = $_POST['CodeAnnee'];
        $CodeMatiere = $_POST['CodeMatiere'];
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $HeureMatiere = '1';

        $db_data = array();
        $sql = "INSERT INTO conduites (DateEnreg, CodeEleve, Nombre, CodeEtatCond, CodeClasse, CodeAnnee, CodeMatiere, CodeEnseignement, HeureMatiere) VALUES ('$DateEnreg','$CodeEleve','$Nombre','','$CodeClasse','$CodeAnnee','$CodeMatiere','$CodeEnseignement','1');";
        // $sql = "INSERT INTO conduites (CodeConduite, DateEnreg, CodeEleve, Nombre, CodeEtatCond, CodeClasse, CodeAnnee, CodeMatiere, HeureMatiere) VALUES ('1','1','1','1','1','1','1','1','1')";
        // $sql = "INSERT INTO conduites ('CodeConduite', 'DateEnreg', 'CodeEleve', 'Nombre', 'CodeEtatCond', 'CodeClasse', 'CodeAnnee', 'CodeMatiere', 'HeureMatiere') VALUES ('$CodeConduite','$DateEnreg','$CodeEleve','$Nombre','$CodeEtatCond','$CodeClasse','$CodeAnnee','$CodeMatiere','$HeureMatiere')";
        $result = mysqli_query($db,$sql);
        $count = mysqli_num_rows($result);
        
        if($result){
            echo json_encode("Success");
        }else{
            echo json_encode("Error");
        }

        $db->close;
        return;
    }

    if('GET_COURSE_ABSENCES' == $action){
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $db_data = array();
        $sql = "SELECT * FROM conduites WHERE CodeEnseignement = '$CodeEnseignement'";
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

    if('GET_COURSE_STUDENT_ABSENCES' == $action){
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $CodeEleve = $_POST['CodeEleve'];

        $db_data = array();
        $sql = "SELECT * FROM conduites WHERE CodeEnseignement = '$CodeEnseignement' AND CodeEleve = '$CodeEleve'";
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

    if('GET_SORTED_COURSE_ABSENCES' == $action){
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $sortedDate = $_POST['sortedDate'];
        $db_data = array();
        $sql = "SELECT * FROM conduites WHERE CodeEnseignement = '$CodeEnseignement' AND DateEnreg = '$sortedDate'";
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

    if('GET_SORTED_STUDENT_ABSENCES' == $action){
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $CodeEleve = $_POST['CodeEleve'];
        $sortedDate = $_POST['sortedDate'];
        $db_data = array();
        $sql = "SELECT * FROM conduites WHERE CodeEleve = '$CodeEleve' AND CodeEnseignement = '$CodeEnseignement' AND DateEnreg = '$sortedDate'";
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

    if('CLEAR' == $action){
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $sortedDate = $_POST['sortedDate'];
        $db_data = array();
        $sql = "DELETE FROM conduites WHERE CodeEnseignement = '$CodeEnseignement' AND DateEnreg = '$sortedDate'";
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

    if('GET_SORTED_COURSE_ABSENT_STUDENTS' == $action){
        $CodeEnseignement = $_POST['CodeEnseignement'];
        $sortedDate = $_POST['sortedDate'];
        $db_data = array();

        $sql = "SELECT * From eleves WHERE CodeEleve IN (SELECT CodeEleve FROM conduites WHERE CodeEnseignement='$CodeEnseignement' AND DateEnreg = '$sortedDate')";


        // $sql = "SELECT * From eleves LEFT JOIN conduites ON eleves.CodeEleve = conduites.CodeEleve AND conduites.DateEnreg = '$sortedDate' AND conduites.CodeEnseignement = '$CodeEnseignement'";
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
        $sql = "SELECT * FROM conduites";
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