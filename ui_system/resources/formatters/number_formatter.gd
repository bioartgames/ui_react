## Number formatter for currency, decimals, and thousand separators.
## Can be used in bindings (as ValueConverter) or text segments (as TextFormatter).
@icon("res://icon.svg")
class_name NumberFormatter
extends TextFormatter

## Currency symbol (e.g., "$", "€", "£"). Empty string for no currency.
@export var currency_symbol: String = ""

## Number of decimal places to show.
@export var decimal_places: int = 2

## Whether to use thousand separators.
@export var use_thousand_separator: bool = true

## Thousand separator character.
@export var thousand_separator: String = ","

## Formats a number with currency, decimals, and thousand separators.
func format(value: Variant) -> String:
	if value == null:
		return ""
	
	# Convert to float for formatting
	var num_value: float = 0.0
	if value is int:
		num_value = float(value as int)
	elif value is float:
		num_value = value as float
	else:
		# Try to convert string to float
		var str_value = str(value)
		if str_value.is_valid_float():
			num_value = str_value.to_float()
		else:
			return str(value)
	
	# Format with decimal places
	var formatted = "%.*f" % [decimal_places, num_value]
	
	# Add thousand separators if enabled
	if use_thousand_separator:
		var parts = formatted.split(".")
		var integer_part = parts[0]
		var decimal_part = parts[1] if parts.size() > 1 else ""
		
		# Add thousand separators to integer part (from right to left)
		var result = ""
		var count = 0
		for i in range(integer_part.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = thousand_separator + result
			result = integer_part[i] + result
			count += 1
		
		formatted = result
		if decimal_part != "":
			formatted += "." + decimal_part
	
	# Add currency symbol
	if currency_symbol != "":
		formatted = currency_symbol + formatted
	
	return formatted

