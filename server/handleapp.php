<?php
	//Implementing CRUD methods
	
	// Connect to database
    $DATABASE_HOST = 'localhost';
	$DATABASE_USER = 'root';
	$DATABASE_PASS = 'example';
	$DATABASE_NAME = 'warehouse';

	// Get and decode JSON string
    $json_str = file_get_contents('php://input');
    $json_obj = json_decode($json_str,true);

	// Create new SQL entry using prepared statements to prevent SQL injection
	if($json_obj['action']=="create"){
		if($json_obj['mode']=="inventory")
			if ($stmt = $con->prepare('INSERT INTO inventory (packagecode, locationcode, quantity, description) VALUES (?,?,?,?)')) {
				
				// Bind parameters (s = string, i = int, b = blob, etc)
				$stmt->bind_param('ssis', $package_code, $location_code, $quantity, $description);
				
				$package_code = $json_obj['package'];
				$location_code = $json_obj['location'];
				$quantity = $json_obj['quantity'];
				$description = $json_obj['description'];

				$stmt->execute();
				$stmt->close();
				$con->close();
				echo 'Package successfully submitted!';
				exit();

			}
			else{
				
				echo($con->error);
				exit();

			}
				

		if($json_obj['mode']=="outgoing")
			if ($stmt = $con->prepare('INSERT INTO outgoing (packageid, trackingnr, note) VALUES (?,?,?)')) {
				
				// Bind parameters (s = string, i = int, b = blob, etc)
				$stmt->bind_param('sss', $package_id, $tracking_nr, $note);
				$package_id = $json_obj['packageid'];
				$tracking_nr = $json_obj['trackingnr'];
				$note = $json_obj['note'];

				$stmt->execute();
				$stmt->close();
				$con->close();
				echo 'Package successfully submitted!';
				exit();
			}
			else{

				echo($con->error);
				exit();

			}
				
	}
	
	// Read existing SQL table data
	// Since this requires no user input a regular SQL query can be used
	if($json_obj['action']=="read"){
		if($json_obj['mode']=="inventory"){

			$sql = "SELECT * FROM inventory ORDER BY id";
			$result = $con->query($sql);
			$db_data = array();

			if($result->num_rows > 0){
				while($row = $result->fetch_assoc())
					$db_data[] = $row;

				echo json_encode($db_data);
			}
			else
				echo "Error: Returned table has no entries";

			$con->close();
			exit();

		}
		if($json_obj['mode']=="outgoing"){

			$sql = "SELECT * FROM outgoing ORDER BY id";
			$result = $con->query($sql);
			$db_data = array();

			if($result->num_rows > 0){
				while($row = $result->fetch_assoc())
					$db_data[] = $row;

				echo json_encode($db_data);
			}
			else
				echo "Error: Returned table has no entries";

			$con->close();
			exit();

		}
	}

	// Update existing SQL entries
	if($json_obj['action']=="update"){
		if($json_obj['mode']=="inventory"){
			if ($stmt = $con->prepare('UPDATE inventory SET packagecode = ?, locationcode = ?, quantity = ?, description = ? WHERE id = ?')) {
				
				// Bind parameters (s = string, i = int, b = blob, etc)
				$stmt->bind_param('ssisi', $package_code, $location_code, $quantity, $description,$id);
				$package_code = $json_obj['package'];
				$location_code = $json_obj['location'];
				$quantity = $json_obj['quantity'];
				$description = $json_obj['description'];
				$id = $json_obj['id'];

				$stmt->execute();
				$stmt->close();
				$con->close();
				echo 'Package successfully updated';
				exit();

			}
			else{
				
				echo($con->error);
				exit();

			}
		}

		if($json_obj['mode']=="outgoing"){
			//if ($stmt = $con->prepare('UPDATE inventory SET packagecode = ?, locationcode = ?, quantity = ?, description = ? WHERE id = ?')) {
				if ($stmt = $con->prepare('UPDATE outgoing SET packageid = ?, trackingnr = ?, note = ? WHERE id = ?')) {
					
					// Bind parameters (s = string, i = int, b = blob, etc)
					$stmt->bind_param('sss', $package_id, $tracking_nr, $note);
					$package_id = $json_obj['packageid'];
					$tracking_nr = $json_obj['trackingnr'];
					$note = $json_obj['note'];
					$id = $json_obj['id'];

					$stmt->execute();
					$stmt->close();
					$con->close();
					echo 'Package successfully updated';
					exit();

				}
				else{

					echo($con->error);
					exit();

				}	
				
		}
	}

	// Delete existing SQL entry based on internal id
	if($json_obj['action']=="delete"){
		if($json_obj['mode']=="inventory"){
			if ($stmt = $con->prepare('DELETE FROM inventory WHERE id =?')) {
				// Bind parameters (s = string, i = int, b = blob, etc)
				$stmt->bind_param('i', $id);
				$id = $json_obj['id'];

				$stmt->execute();
				$stmt->close();
				$con->close();
				echo 'Package successfully deleted';
				exit();

			}
			else{

				echo($con->error);
				exit();
			
			}
		}

		if($json_obj['mode']=="outgoing"){
			if ($stmt = $con->prepare('DELETE FROM outgoing WHERE id =?')) {
				// Bind parameters (s = string, i = int, b = blob, etc)
				$stmt->bind_param('i', $id);
				$id = $json_obj['id'];

				$stmt->execute();
				$stmt->close();
				$con->close();
				echo 'Package successfully deleted';
				exit();

			}
			else{

				echo($con->error);
				exit();
			
			}
		}		
	}
?>