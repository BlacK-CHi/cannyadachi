extends Control

func set_error_text(errorLevel: String, errorText: String):
	$Control/ErrorLevel.text = errorLevel
	$Control/ErrorText.text = errorText
