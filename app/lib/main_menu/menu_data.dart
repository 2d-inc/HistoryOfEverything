import 'dart:convert';
import 'dart:ui';
import "package:flutter/services.dart" show rootBundle;

class MenuSectionData
{
	String label;
	Color textColor;
	Color backgroundColor;
	String assetId;
	List<MenuItemData> items = new List<MenuItemData>();
}

class MenuItemData
{
	String label;
	double start;
	double end;

    MenuItemData();
    MenuItemData.fromData(this.label,  this.start, this.end);
}

class MenuData
{
	List<MenuSectionData> sections = [];
	Future<bool> loadFromBundle(String filename) async
	{
		List<MenuSectionData> menu = new List<MenuSectionData>();
		String data = await rootBundle.loadString(filename);
		List jsonEntries = json.decode(data) as List;
		for(dynamic entry in jsonEntries)
		{
			Map map = entry as Map;
			
			if(map != null)
			{
				MenuSectionData menuSection = new MenuSectionData();
				menu.add(menuSection);
				if(map.containsKey("label"))
				{
					menuSection.label = map["label"] as String;
				}
				if(map.containsKey("background"))
				{
					menuSection.backgroundColor = new Color(int.parse((map["background"] as String).substring(1, 7), radix: 16) + 0xFF000000);
				}
				if(map.containsKey("color"))
				{
					menuSection.textColor = new Color(int.parse((map["color"] as String).substring(1, 7), radix: 16) + 0xFF000000);
				}
				if(map.containsKey("asset"))
				{
					menuSection.assetId = map["asset"] as String;
				}
				if(map.containsKey("items"))
				{
					List items = map["items"] as List;
					for(dynamic item in items)
					{
						Map itemMap = item as Map;
						if(itemMap == null)
						{
							continue;
						}
						MenuItemData itemData = new MenuItemData();
						if(itemMap.containsKey("label"))
						{
							itemData.label = itemMap["label"] as String;
						}
						if(itemMap.containsKey("start"))
						{
							dynamic start = itemMap["start"];
							itemData.start = start is int ? start.toDouble() : start;
						}
						if(itemMap.containsKey("end"))
						{
							dynamic end = itemMap["end"];
							itemData.end = end is int ? end.toDouble() : end;
						}
						menuSection.items.add(itemData);
					}
				}
			}
		}
		sections = menu;
		return true;
	}
}