<?php
    $db = mysqli_connect('localhost','root','','STUDMANBORROMEE');
    if(!$db){
        echo "Database Connection Failed !";
    }
    
    $action = $_POST['action'];
    if('LOGIN' == $action){
        
        $login = trim((string) ($_POST['login'] ?? ''));
        $text_password = (string) ($_POST['text_password'] ?? '');
        
        $db_data = array();
        $statement = $db->prepare(
            'SELECT nom, prenom, contacts, sex, email, login, code, account_type, text_password, address, admin, CodeEtablissement FROM users WHERE login = ? AND text_password = ? LIMIT 1'
        );
        $statement->bind_param('ss', $login, $text_password);
        $statement->execute();
        $result = $statement->get_result();
        $count = $result->num_rows;
        
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

    if('CHANGE PASSWORD' == $action){
        
        $login = trim((string) ($_POST['login'] ?? ''));
        $new_password = (string) ($_POST['new_password'] ?? '');

        if ($login === '' || $new_password === '') {
            echo json_encode("Error");
            $db->close();
            return;
        }

        $db->begin_transaction();
        try {
            $current_password = (string) ($_POST['current_password'] ?? '');
            if ($current_password === '') {
                $db->rollback();
                echo json_encode("Error");
                $db->close();
                return;
            }

            $find_user = $db->prepare(
                'SELECT code, password, text_password FROM users WHERE login = ? LIMIT 1'
            );
            $find_user->bind_param('s', $login);
            $find_user->execute();
            $user_result = $find_user->get_result();

            if ($user_result->num_rows === 0) {
                $db->rollback();
                echo json_encode("Error");
                $db->close();
                return;
            }

            $user_row = $user_result->fetch_assoc();
            $stored_hash = (string) ($user_row['password'] ?? '');
            $stored_text_password = (string) ($user_row['text_password'] ?? '');
            $hash_matches = $stored_hash !== ''
                && password_get_info($stored_hash)['algo'] !== 0
                && password_verify($current_password, $stored_hash);
            $legacy_matches = $stored_text_password !== ''
                && (
                    hash_equals(
                        rtrim($stored_text_password),
                        rtrim($current_password)
                    )
                    || strcasecmp(
                        rtrim($stored_text_password),
                        rtrim($current_password)
                    ) === 0
                );

            if (!$hash_matches && !$legacy_matches) {
                $db->rollback();
                echo json_encode("Error");
                $db->close();
                return;
            }

            $password_hash = password_hash($new_password, PASSWORD_BCRYPT);
            $update_user = $db->prepare(
                'UPDATE users SET text_password = ?, password = ? WHERE login = ?'
            );
            $update_user->bind_param('sss', $new_password, $password_hash, $login);
            if (!$update_user->execute()) {
                throw new Exception('Password update failed');
            }

            $db->commit();
            echo json_encode("Success");
        } catch (Throwable $exception) {
            $db->rollback();
            echo json_encode("Error");
        }
        
        $db->close();
        return;
    }

    if('GET_ALL' == $action){
        $db_data = array();
        $sql = "SELECT * FROM users";
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