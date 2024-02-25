<?php
// Create connection to the database
$con = mysqli_connect("localhost", "root", "student123456789", "now_app");

// Check connection
if (mysqli_connect_errno()) {
    echo "Failed to connect to MySQL: " . mysqli_connect_error();
}

// Values sent from the client with a POST request
$username = $con->real_escape_string($_POST['username']);
$password = $con->real_escape_string($_POST['password']);

// Check password requirements
if (!(strlen($password) >= 8 && preg_match('/[0-9]/', $password) && preg_match('/[A-Z]/', $password))) {
    echo json_encode(array("result" => "Password must be at least 8 characters long and contain at least one number and one uppercase letter."));
    mysqli_close($con);
    exit;
}

// Check if the username already exists
$stmtCheck = $con->prepare("SELECT COUNT(*) FROM users WHERE username = ?");
$stmtCheck->bind_param("s", $username);
$stmtCheck->execute();
$stmtCheck->bind_result($count);
$stmtCheck->fetch();
$stmtCheck->close();

if ($count > 0) {
    echo json_encode(array("result" => "Username already exists. Choose a different one."));
} else {
    // Insert new user
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT); // Hash the password for security
    $stmt = $con->prepare("INSERT INTO users (username, password) VALUES (?, ?)");
    $stmt->bind_param("ss", $username, $hashedPassword);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        echo json_encode(array("result" => "Registration successful!"));
    } else {
        echo json_encode(array("result" => "Registration failed. Please try again."));
    }

    $stmt->close();
}

mysqli_close($con);
?>
