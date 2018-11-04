import 'dart:io';
import 'package:image/image.dart';

// This tool resizes large images.
const String source = "../app/full_quality";
const String dest = "../app/assets";

const int ThresholdSize = 1024;

void main() 
{
	new Directory("../app/full_quality").list(recursive: true, followLinks: false)
    .listen((FileSystemEntity entity) 
	{
		int dot = entity.path.lastIndexOf(".");
		if(dot != -1)
		{
			String extension = entity.path.substring(dot+1).toLowerCase();
			if(extension == "png")
			{
				Image image = decodeImage(new File(entity.path).readAsBytesSync());
				if(image.width > ThresholdSize || image.height > ThresholdSize)
				{
					print("Large image: ${image.width}x${image.height} - ${entity.path}");
					String destFilename = dest + entity.path.substring(source.length);
					
					Image thumbnail = image.width > ThresholdSize ? copyResize(image, ThresholdSize, -1) : copyResize(image, -1, ThresholdSize);
					new File(destFilename)..writeAsBytesSync(encodePng(thumbnail));
					print("Wrote to: $destFilename");
				}
			}
		}
    });
}