import 'dart:convert';
import "package:flutter/services.dart" show rootBundle;

class MenuSectionData
{
	String label;
	List<MenuItemData> items = new List<MenuItemData>();
}

class MenuItemData
{
	String label;
	double start;
	double end;
}

class MenuData
{
	List<MenuSectionData> sections;
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
							itemData.label = item["label"] as String;
						}
						if(itemMap.containsKey("start"))
						{
							dynamic start = map["start"];
							itemData.start = start is int ? start.toDouble() : start;
						}
						if(itemMap.containsKey("end"))
						{
							dynamic end = map["end"];
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