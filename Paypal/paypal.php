<?php

$query1 = "";
$query1 = $query1."select txn_id, item_number, quantity from jos_pinp_transactions where invoice = ".$id." and payment_status='Completed' and inserted='0' order by txn_id";
$result = mysql_query($query1);
while ($thisrow=mysql_fetch_row($result))
{
while ($row=mysql_fetch_array($result))
{
//calculate # of lics per txn_id
if ($result[item_number] = 2) // Einzellizenz
{$lic_quantity = $result[quantity];}
if ($result[item_number] = 3) // 3er Pack
{$lic_quantity = ( 3 * $result[quantity]);}
//update databases
for ($count=1; $count < $lic_quantity; $count++)
{
//update query
$query4 = "";
$query4 = " update table sx_lic as t1 inner join jos_pinp_trancactions t2";
$query4 = $query4." set t1.user_id = t2.invoice";
$query4 = $query4." set t1.txn_id = t2.txn_id"."_".$count;
$query4 = $query4." set t1.article_id = t2.item_number";
$query4 = $query4." set t1.article_quantity = t2.quantity";
$query4 = $query4." set t1.activated = '0'";
$query4 = $query4." where t2.payment_status = 'Completed' and t2.invoice=$id and t1.activated ='0' ";
$execute = mysql_query($query4) or die;
}
//update Paypal-Table
$query5 = ""
$query5 = " update table jos_pinp_transactions";
$query5 = $query5." set inserted = '1'";
$query5 = $query5." where txn_id = ".$result[txn_id];
$query5 = $query5." and invoice = ".$id;
$paypal_update = mysql_query($query5) or die;
}
}

?>

---------------------------------------------------------------------------------------------------

$result = mysql_query("SELECT * FROM members WHERE last=$last AND first=$first ORDER BY last"); 

// And now we need to output an XML document 
// We use the names of columns as <row> properties. 

echo '<?xml version="1.0" encoding="UTF-8"?>'; 
echo '<datapacket>'; 
while($row=mysql_fetch_array($result)){ 
    $line = '<member last="'.$row[last].'" first="'.$row[first].'" user="'.$row[user].'" pass="'.$row[pass].'" address1="'.$row[address1].'" address2="'.$row[address2].'" city="'.$row[city].'" state="'.$row[state].'" zip="'.$row[zip].'" home="'.$row[home].'" work="'.$row[work].'" fax="'.$row[fax].'" email="'.$row[email].'" photo="'.$row[photo].'"/>'; 
    echo $line; 
} 
echo '</datapacket>'; 
?>
-------------------------------------------------------------------
while($thisrow=mysql_fetch_row($item))
{
  $i=0;
  while ($i < mysql_num_fields($item))
  {
    $field_name=mysql_fetch_field($item, $i);
    //just for testing - display all the fields
echo $thisrow[$i] . " ";  //Display all the fields on one line -- just 
    $i++;
  }

--------------------------------------------------------------------------
$query1="select * from " . $mainsection . " as t1 where ((t1.active and t1.approved)
  and (t1.cat1 = \"" . $section . "\"  or t1.cat2 = \"" . $section . "\" or t1.cat3 = \"" . $section . "\"))
  order by t1.score DESC, t1.hits DESC";  //select all approved links that belong to the current category
$result = mysql_db_query($dbname, $query1) or die("Failed Query of " . $query1);  //do the query
while($thisrow=mysql_fetch_row($result))
{
  $i=0;
  while ($i < mysql_num_fields($result))
  {
    $field_name=mysql_fetch_field($result, $i);
    echo $thisrow[$i] . " ";  //Display all the fields on one line
    $i++;
  }
echo <br>";  //put a break after each database entry

---------------------------------------------------------------------------
