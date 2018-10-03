import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "dart:ui" as ui;
import "package:flutter/services.dart" show rootBundle;

typedef PaintCallback();

enum TimelineEntryType
{
	Era,
	Incident
}

class TimelineEntryAsset
{
	ui.Image image;
	double width;
	double height;
	double opacity = 0.0;
	double scale = 0.0;
	double scaleVelocity = 0.0;
	double y = 0.0;
	double velocity = 0.0;
}

class TimelineEntry
{
	TimelineEntryType type;
	double start;
	double end;
	String label;

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

	TimelineEntryAsset asset;
}

class Timeline
{
	double _start = 0.0;
	double _end = 0.0;
	double _renderStart;
	double _renderEnd;
	double _velocity = 0.0;
	double _lastFrameTime = 0.0;
	double _height = 0.0;
	List<TimelineEntry> _entries;
	List<TimelineEntryAsset> _renderAssets;
	double _lastEntryY = 0.0;
	double _offsetDepth = 0.0;
	double _renderOffsetDepth = 0.0;
	double _labelX = 0.0;
	double _renderLabelX = 0.0;
	bool _isFrameScheduled = false;
	bool isInteracting = false;
	double _lastAssetY = 0.0;

	List<TimelineEntry> get entries => _entries;
	double get renderOffsetDepth => _renderOffsetDepth;
	double get renderLabelX => _renderLabelX;
	List<TimelineEntryAsset> get renderAssets => _renderAssets;

	PaintCallback onNeedPaint;
	double get start => _start;
	double get end => _end;
	double get renderStart => _renderStart;
	double get renderEnd => _renderEnd;

	static const double LineWidth = 2.0;
	static const double LineSpacing = 10.0;
	static const double DepthOffset = LineSpacing+LineWidth;

	static const double EdgePadding = 8.0;
	static const double FadeAnimationStart = 55.0;
	static const double MoveSpeed = 20.0;
	static const double Deceleration = 9.0;
	static const double GutterLeft = 45.0;
	
	static const double EdgeRadius = 4.0;
	static const double MinChildLength = 50.0;
	static const double MarginLeft = GutterLeft + LineSpacing;
	static const double BubbleHeight = 50.0;
	static const double BubbleArrowSize = 19.0;
	static const double BubblePadding = 20.0;
	static const double AssetPadding = 30.0;
	static const double Parallax = 100.0;
	static const double AssetScreenScale = 0.25;

	Timeline()
	{
		loadFromBundle("assets/timeline.json").then((bool success)
		{
			// Double check: Make sure we have height by now...
			double scale = _height == 0.0 ? 1.0 : _height/(_entries.first.end-_entries.first.start);
			// We use the scale to pad by the bubble height when we set the first range.
			setViewport(start: _entries.first.start - BubbleHeight/scale, end: _entries.first.end + BubbleHeight/scale, animate:true);
			advance(0.0, false);
		});
		setViewport(start: 1536.0, end: 3072.0);
	}

	Future<bool> loadFromBundle(String filename) async
	{
		List<TimelineEntry> allEntries = new List<TimelineEntry>();
		String data = await rootBundle.loadString(filename);
		List jsonEntries = json.decode(data) as List;
		for(dynamic entry in jsonEntries)
		{
			Map map = entry as Map;
			
			if(map != null)
			{
				TimelineEntry timelineEntry = new TimelineEntry();
				if(map.containsKey("date"))
				{
					timelineEntry.type = TimelineEntryType.Incident;
					dynamic date = map["date"];
					timelineEntry.start = date is int ? date.toDouble() : date;
				}
				else if(map.containsKey("start"))
				{
					timelineEntry.type = TimelineEntryType.Era;
					dynamic start = map["start"];
					timelineEntry.start = start is int ? start.toDouble() : start;
				}
				else
				{
					continue;
				}

				if(map.containsKey("end"))
				{
					dynamic end = map["end"];
					timelineEntry.end = end is int ? end.toDouble() : end;
				}
				else if(timelineEntry.type == TimelineEntryType.Era)
				{
					timelineEntry.end = DateTime.now().year.toDouble();
				}
				else
				{
					timelineEntry.end = timelineEntry.start;
				}

				if(map.containsKey("label"))
				{
					timelineEntry.label = map["label"] as String;
				}

				if(map.containsKey("asset"))
				{
					TimelineEntryAsset asset = new TimelineEntryAsset();
					Map assetMap = map["asset"] as Map;
					String source = assetMap["source"];
					ByteData data = await rootBundle.load("assets/" + source);
					Uint8List list = new Uint8List.view(data.buffer);
					ui.Codec codec = await ui.instantiateImageCodec(list);
					ui.FrameInfo frame = await codec.getNextFrame();
					asset.image = frame.image;
					
					dynamic width = assetMap["width"];
					asset.width = width is int ? width.toDouble() : width;
					dynamic height = assetMap["height"];
					asset.height = height is int ? height.toDouble() : height;

					timelineEntry.asset = asset;
				}
				allEntries.add(timelineEntry);
			}
		}

		// sort the full list so they are in order of oldest to newest
		allEntries.sort((TimelineEntry a, TimelineEntry b)
		{
			return a.start.compareTo(b.start);
		});

		_entries = new List<TimelineEntry>();
		// build up hierarchy (eras are grouped into spanning eras and events are placed into the eras they belong to)
		for(TimelineEntry entry in allEntries)
		{
			TimelineEntry parent;
			double minDistance = double.maxFinite;
			for(TimelineEntry checkEntry in allEntries)
			{
				if(checkEntry.type == TimelineEntryType.Era)
				{
					double distance = entry.start - checkEntry.start;
					double distanceEnd = entry.start - checkEntry.end;
					if(distance > 0 && distanceEnd < 0 && distance < minDistance)
					{
						minDistance = distance;
						parent = checkEntry;
					}
				}
			}
			if(parent != null)
			{
				entry.parent = parent;
				if(parent.children == null)
				{
					parent.children = new List<TimelineEntry>();
				}
				parent.children.add(entry);
			}
			else
			{
				// item doesn't  have a parent, so it's one of our root entries.
				_entries.add(entry);
			}
		}

		return true;	
	}

	void setViewport({double start = double.maxFinite, double end = double.maxFinite, double height = double.maxFinite, double velocity = double.maxFinite, bool animate = false})
	{
		if(start != double.maxFinite)
		{
			_start = start;
		}
		if(end != double.maxFinite)
		{
			_end = end;
		}
		if(height != double.maxFinite)
		{
			if(_height == 0.0 && _entries != null && _entries.length > 0)
			{
				double scale = height/(_entries.first.end-_entries.first.start);
				_start = _start + BubbleHeight/scale;
				_end = _end - BubbleHeight/scale;
			}
			_height = height;
		}
		if(velocity != double.maxFinite)
		{
			_velocity = velocity;
		}
		if(!animate)
		{
			_renderStart = start;
			_renderEnd = end;
			if(onNeedPaint != null)
			{
				onNeedPaint();
			}
		}
		else if(!_isFrameScheduled)
		{
			_isFrameScheduled = true;
			_lastFrameTime = 0.0;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
	}

	void beginFrame(Duration timeStamp) 
	{
		_isFrameScheduled = false;
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			return;
		}

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;

		if(!advance(elapsed, true) && !_isFrameScheduled)
		{
			_isFrameScheduled = true;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}

		if(onNeedPaint != null)
		{
			onNeedPaint();
		}
	}

	bool advance(double elapsed, bool animate)
	{
		double scale = _height/(_renderEnd-_renderStart);

		// Attenuate velocity and displace targets.
		_velocity *= 1.0 - min(1.0, elapsed*Deceleration);
		double displace = _velocity*elapsed;
		_start -= displace;
		_end -= displace;

		// Animate movement.
		double speed = min(1.0, elapsed*MoveSpeed);
		double ds = _start - _renderStart;
		double de = _end - _renderEnd;
		
		bool doneRendering = true;
		bool isScaling = true;
		if(!animate || ((ds*scale).abs() < 1.0 && (de*scale).abs() < 1.0))
		{
			isScaling = false;
			_renderStart = _start;
			_renderEnd = _end;
		}
		else
		{
			doneRendering = false;
			_renderStart += ds*speed;
			_renderEnd += de*speed;
		}

		// Update scale after changing render range.
		scale = _height/(_renderEnd-_renderStart);

		_lastEntryY = -double.maxFinite;
		_lastAssetY = -double.maxFinite;
		_labelX = 0.0;
		_offsetDepth = 0.0;
		
		if(_entries != null)
		{
			if(advanceItems(_entries, MarginLeft, scale, elapsed, animate, 0))
			{
				doneRendering = false;
			}

			_renderAssets = new List<TimelineEntryAsset>();
			if(advanceAssets(_entries, elapsed, animate, _renderAssets))
			{
				doneRendering = false;
			}
		}
		
		double dl = _labelX - _renderLabelX;
		if(!animate || dl.abs() < 1.0)
		{
			_renderLabelX = _labelX;
		}
		else
		{
			doneRendering = false;
			_renderLabelX += dl*min(1.0, elapsed*6.0);
		}

		if(!isInteracting && !isScaling)
		{
			double dd = _offsetDepth - renderOffsetDepth;
			if(!animate || dd.abs()*DepthOffset < 1.0)
			{
				_renderOffsetDepth = _offsetDepth;
			}
			else
			{
				doneRendering = false;
				_renderOffsetDepth += dd*min(1.0, elapsed*12.0);
			}
		}

		return doneRendering;
	}

	bool advanceItems(List<TimelineEntry> items, double x, double scale, double elapsed, bool animate, int depth)
	{
		bool stillAnimating = false;
		double lastEnd = -double.maxFinite;
		for(int i = 0; i < items.length; i++)
		//for(TimelineEntry item in items)
		{
			TimelineEntry item = items[i];
			
			double start = item.start-_renderStart;
			double end = item.type == TimelineEntryType.Era ? item.end-_renderStart : start;
			// double length = (end-start)*scale-2*EdgePadding;
			// double pad = EdgePadding;//(length/EdgePadding).clamp(0.0, 1.0)*EdgePadding;

			//item.length = length = max(0.0, (end-start)*scale-pad*2.0);

			double y = start*scale;//+pad;
			if(i > 0 && y - lastEnd < EdgePadding)
			{
				y = lastEnd + EdgePadding;
			}
			double endY = end*scale;//-pad;
			lastEnd = endY;

			item.length = endY - y;

			double targetLabelOpacity = y - _lastEntryY < FadeAnimationStart ? 0.0 : 1.0;
			double dt = targetLabelOpacity - item.labelOpacity;
			if(!animate || dt.abs() < 0.01)
			{
				item.labelOpacity = targetLabelOpacity;	
			}
			else
			{
				stillAnimating = true;
				item.labelOpacity += dt * min(1.0, elapsed*25.0);
			}
			
			item.y = y;
			item.endY = endY;

			double targetLegOpacity = item.length > EdgeRadius ? 1.0 : 0.0;
			double dtl = targetLegOpacity - item.legOpacity;
			if(!animate || dtl.abs() < 0.01)
			{
				item.legOpacity = targetLegOpacity;	
			}
			else
			{
				stillAnimating = true;
				item.legOpacity += dtl * min(1.0, elapsed*20.0);
			}


			double targetItemOpacity = item.parent != null ? item.parent.length < MinChildLength || (item.parent != null && item.parent.endY < y) ? 0.0 : y > item.parent.y ? 1.0 : 0.0 : 1.0;
			dtl = targetItemOpacity - item.opacity;
			if(!animate || dtl.abs() < 0.01)
			{
				item.opacity = targetItemOpacity;	
			}
			else
			{
				stillAnimating = true;
				item.opacity += dtl * min(1.0, elapsed*20.0);
			}

			// if(item.labelY === undefined)
			// {
			// 	item.labelY = y;
			// }
			
			double targetLabelVelocity = y - item.labelY;
			// if(item.velocity === undefined)
			// {
			// 	item.velocity = 0.0;
			// }
			double dvy = targetLabelVelocity - item.labelVelocity;
			item.labelVelocity += dvy * elapsed*18.0;

			item.labelY += item.labelVelocity * elapsed*20.0;
			if(animate && (item.labelVelocity.abs() > 0.01 || targetLabelVelocity.abs() > 0.01))
			{
				stillAnimating = true;
			}
			
			_lastEntryY = y;

			
			if(item.type == TimelineEntryType.Era && y < 0 && endY > _height && depth > _offsetDepth)
			{
				_offsetDepth = depth.toDouble();
			}

			if(y > _height + BubbleHeight || endY < -BubbleHeight)
			{
				item.labelY = y;
				continue;
			}

			double lx = x + LineSpacing + LineSpacing;
			if(lx > _labelX)
			{
				_labelX = lx;	
			}

			if(item.children != null && item.isVisible)
			{
				if(advanceItems(item.children, x + LineSpacing + LineWidth, scale, elapsed, animate, depth+1))
				{
					stillAnimating = true;
				}
			}
		}
		return stillAnimating;
	}

	bool advanceAssets(List<TimelineEntry> items, double elapsed, bool animate, List<TimelineEntryAsset> renderAssets)
	{
		bool stillAnimating = false;
		for(TimelineEntry item in items)
		{
			if(item.asset != null)
			{
				double y = item.y;
				double halfHeight = _height/2.0;
				double thresholdAssetY = y+((y-halfHeight)/halfHeight)*Parallax;//item.asset.height*AssetScreenScale/2.0;
				double targetAssetY = thresholdAssetY-item.asset.height*AssetScreenScale/2.0; 
				double targetAssetOpacity = (thresholdAssetY - _lastAssetY < 0 ? 0.0 : 1.0) * item.opacity * item.labelOpacity;

				double targetScale = targetAssetOpacity;
				double targetScaleVelocity = targetScale - item.asset.scale;
				if(!animate || targetScale == 0)
				{
					item.asset.scaleVelocity = targetScaleVelocity;
				}
				else
				{
					double dvy = targetScaleVelocity - item.asset.scaleVelocity;
					item.asset.scaleVelocity += dvy * elapsed*18.0;
				}

				item.asset.scale += item.asset.scaleVelocity * elapsed*20.0;//Math.min(1.0, elapsed*(10.0+f*35));
				if(animate && (item.asset.scaleVelocity.abs() > 0.01 || targetScaleVelocity.abs() > 0.01))
				{
					stillAnimating = true;
				}

				double da = targetAssetOpacity - item.asset.opacity;
				if(!animate || da.abs() < 0.01)
				{
					item.asset.opacity = targetAssetOpacity;	
				}
				else
				{
					stillAnimating = true;
					item.asset.opacity += da * min(1.0, elapsed*15.0);
				}

				if(item.asset.opacity > 0.0) // visible
				{
					renderAssets.add(item.asset);
					// if(item.asset.y === undefined)
					// {
					// 	item.asset.y = Math.max(this._lastAssetY, targetAssetY);
					// }

					double targetAssetVelocity = max(_lastAssetY, targetAssetY) - item.asset.y;
					double dvay = targetAssetVelocity - item.asset.velocity;
					item.asset.velocity += dvay * elapsed*15.0;

					item.asset.y += item.asset.velocity * elapsed*17.0;//Math.min(1.0, elapsed*(10.0+f*35));
					if(item.asset.velocity.abs() > 0.01 || targetAssetVelocity.abs() > 0.01)
					{
						stillAnimating = true;
					}

					_lastAssetY = /*item.assetY*/targetAssetY + item.asset.height * AssetScreenScale /*renderScale(item.asset.scale)*/ + AssetPadding;
				}	
				else
				{
					item.asset.y = max(_lastAssetY, targetAssetY);
				}
			}

			if(item.children != null && item.isVisible)
			{
				if(advanceAssets(item.children, elapsed, animate, renderAssets))
				{
					stillAnimating = true;
				}
			}
		}
		return stillAnimating;
	}
}