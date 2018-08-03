# walk through the two objects and generate a diff
# This extends compare-object which itself only does shallow comparisons.

# To use, import-module <thisFileName>
#  Compare-DeepObject $foo $bar

function Compare-DeepObject {
	[CmdletBinding()]
	param (
	[Parameter(Mandatory=$true)][AllowNull()][System.Object] $a,
	[Parameter(Mandatory=$true)][AllowNull()][System.Object] $b
# TODO: max-depth
	)
	PROCESS {

# if one side is null, return the other side.
if($a -eq $null -and $b -ne $null) { return @{ a=$null; b=$b} }
if($b -eq $null -and $a -ne $null) { return @{ b=$null; a=$a} }
if($a -eq $null -and $b -eq $null) { return }

# compare data types
if(Compare-Object $a.PSObject.TypeNames $b.PSObject.TypeNames) {
	return @{ _typeMismatch = "Data type mismatch"; a = $a.PSObject.TypeNames; b = $b.PSObject.TypeNames }
}

$differences = @{} # accumulate differences here.
if($a -is [array]) { # Recurse for each element of an array
	if($a.count -ne $b.count) { $differences["_count"] = "Element count mismatch" }

	for($i = 0; $i -lt [math]::max($a.length, $b.length); $i++) {
		#recurse
		if($d = Compare-DeepObject $a[$i] $b[$i]) {
			$differences["array element $i"] = $d
		}
	}
} elseif($a -is [hashtable]) { # Recurse for each element of a hashtable
	if($a.count -ne $b.count) { $differences["_count"] = "Element count mismatch" }

	# walk both sets of keys with this cool get-unique magic.
	foreach($k in @(@($a.keys)+ @($b.keys) | get-unique)) {
		#recurse
		if($d = Compare-DeepObject $a[$k] $b[$k]) {
			$differences[$k] = $d
		}
	}
} elseif($a -is [PSCustomObject]) { # Recurse for each property of a PSCustomObject
	if($a.PSObject.properties.name.count -ne $b.PSObject.properties.name.count) { $differences["_count"] = "Element count mismatch" }

	# walk both sets of keys^Wproperty names with this cool get-unique magic.
	foreach($k in @(@($a.PSObject.properties.name) + @($b.PSObject.properties.name) | get-unique)) {
		#recurse
		if($d = Compare-DeepObject $a.$k $b.$k) {
			$differences[$k] = $d
		}
	}
}
# If we are a complex object with differences, they should be accumulated and returned now.
if($differences.count) { return $differences }

# We are not a complex object with differences.  actually compare what we have now.
if(Compare-Object $a $b) {
	return @{a = $a; b = $b}
}

	} # End PROCESS
} # End function$