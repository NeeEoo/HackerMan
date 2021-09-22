class HelperFunctions
{
	public static function truncateFloat(number:Float, precision:Int):Float {
		var perc = Math.pow(10, precision);
		return Math.round(number * perc) / perc;
	}
}