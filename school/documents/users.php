<?php
    $db = mysqli_connect('localhost','root','','contact_application');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];

    if('GET_ALL' == $action){
        $db_data = array();
        $sql = "SELECT * FROM contacts";
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
    if("CREATE_TABLE" == $action){
        $sql = "CREATE TABLE IF NOT EXISTS contacts (
            id Int(6) UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
            firstName VARCHAR(30) NULL,
            lastName VARCHAR(30) NULL,
            phoneNumber VARCHAR(30) NULL,
            gender BIT(1) NOT NULL,
            created_at DATETIME NOT NULL
            )";
            $result = mysqli_query($db, $sql);
            if($result){
                echo "success";
            }else{
                echo "Error";
            }
            $conn->close();
            return;
    }

    if('GET_ALL' == $action){
        $db_data = array();
        $sql = "SELECT * FROM contacts ORDER BY id DESC";
        $result = mysqli_query($db, $sql);

        if($result->num_rows > 0){
            while($row = $result->fetch_assoc()){
                $db_data[] = $row;
            }
            echo json_encode($db_data);
        }else{
            echo "error";
        }
        $conn->close();
        return;
    }

    if('ADD_CONTACT' == $action){
        echo "ADDING CONTACT";
        $firstName = "cslisted";
        $lastName = "INC";
        $phoneName = '652686163';
        $gender = '0';

        
        $sql = "INSERT INTO users (firstName, lastName, phoneNumber, gender) VALUES ('$firstName','$lastName','$phoneName','$gender')";

        // if($conn->query($sql) == TRUE){
        //     echo "success";
        // }else{
        //     echo "error";
        // }
        $conn->close();
        return;
    }

    if('UPDATE_CONTACT' == $action){
        $id = $_POST['id'];
        $firstName = $_POST['firstName'];
        $lastName = $_POST['lastName'];
        $phoneName = $_POST['phoneNumber'];
        $gender = $_POST['gender'];

        $sql = "UPDATE contacts SET firstName = '$firstName', lastName = '$lastName', 'phoneNumber'='$phoneName','gender'='$gender' WHERE id = '$id'";
        $result = $conn->query($sql);

        if($conn->query($sql) == TRUE){
            echo "success";
        }else{
            echo "error";
        }
        $conn->close();
        return;
    }

    if('DELETE_CONTACT' == $action){
        $id = $_POST['id'];
        $sql = "DELETE WHERE id = '$id'";
        $result = $conn->query($sql);

        if($conn->query($sql) == TRUE){
            echo "success";
        }else{
            echo "error";
        }
        $conn->close();
        return;
    }

?>