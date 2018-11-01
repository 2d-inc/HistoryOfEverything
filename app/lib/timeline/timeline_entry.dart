class TimelineAsset
{
	double width;
	double height;
	double opacity = 0.0;
	double scale = 0.0;
	double scaleVelocity = 0.0;
	double y = 0.0;
	double velocity = 0.0;
}

enum TimelineEntryType
{
	Era,
	Incident
}

class TimelineEntry
{
	TimelineEntryType type;
	double start;
	double end;
	String label;
	String articleFilename;

	TimelineEntry parent;
	List<TimelineEntry> children;

	double y = 0.0;
	double endY = 0.0;
	double length = 0.0;
	double opacity = 0.0;
	double labelOpacity = 0.0;
	double legOpacity = 0.0;
	double labelY = 0.0;
	double labelVelocity = 0.0;

	bool get isVisible
	{
		return opacity > 0.0;
	}

	TimelineAsset asset;


    String formatYearsAgo()
    {
        return TimelineEntry.formatYears(start) + " Ago";
    }

    @override
    String toString()
    {
        return "TIMELINE ENTRY: $label -($start,$end)";
    }

	static String formatYears(double start)
	{
		String label;
        int valueAbs = start.round().abs();
        if(valueAbs > 1000000000)
        {
            double v = (valueAbs/100000000.0).floorToDouble()/10.0;
            
            label = (valueAbs/1000000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Billion";
        }
        else if(valueAbs > 1000000)
        {
            double v = (valueAbs/100000.0).floorToDouble()/10.0;
            label = (valueAbs/1000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Million";
        }
        else if(valueAbs > 10000) // N.B. < 10,000
        {
            double v = (valueAbs/100.0).floorToDouble()/10.0;
            label = (valueAbs/1000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Thousand";
        }
        else
        {
            label = valueAbs.toStringAsFixed(0);
        }
        return label + " Years";
	}
}