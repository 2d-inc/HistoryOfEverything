import 'dart:async';
import "dart:convert";
import "dart:math";
import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/scheduler.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:nima/nima.dart" as nima;
import "package:nima/nima/actor_image.dart" as nima;
import "package:nima/nima/animation/actor_animation.dart" as nima;
import "package:nima/nima/math/aabb.dart" as nima;
import "package:nima/nima/math/vec2d.dart" as nima;
import "package:flare/flare.dart" as flare;
import "package:flare/flare/animation/actor_animation.dart" as flare;
import "package:flare/flare/math/aabb.dart" as flare;
import "package:flare/flare/math/vec2d.dart" as flare;
import "timeline_entry.dart";
import "package:timeline/search_manager.dart";
typedef PaintCallback();
typedef ChangeEraCallback(TimelineEntry era);

String getExtension(String filename)
{
	int dot = filename.lastIndexOf(".");
	if(dot == -1)
	{
		return null;
	}
	return filename.substring(dot+1);
}

String removeExtension(String filename)
{
	int dot = filename.lastIndexOf(".");
	if(dot == -1)
	{
		return null;
	}
	return filename.substring(0, dot);
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
	Map<String, TimelineEntry> _entriesById = new Map<String, TimelineEntry>();
	List<TimelineAsset> _renderAssets;
	double _lastEntryY = 0.0;
	double _lastOnScreenEntryY = 0.0;
	double _offsetDepth = 0.0;
	double _renderOffsetDepth = 0.0;
	double _labelX = 0.0;
	double _renderLabelX = 0.0;
	bool _isFrameScheduled = false;
	bool _isInteracting = false;
	double _lastAssetY = 0.0;
	bool isActive = false;
	TimelineEntry _nextEntry;
	TimelineEntry _renderNextEntry;
	TimelineEntry _currentEra;
	TimelineEntry _lastEra;
	double _nextEntryOpacity = 0.0;
	double _distanceToNextEntry = 0.0;

	TimelineEntry get currentEra => _currentEra;

	List<TimelineEntry> get entries => _entries;
	double get renderOffsetDepth => _renderOffsetDepth;
	double get renderLabelX => _renderLabelX;
	List<TimelineAsset> get renderAssets => _renderAssets;
	Map<String, nima.FlutterActor> _nimaResources = new Map<String, nima.FlutterActor>();
	Map<String, flare.FlutterActor> _flareResources = new Map<String, flare.FlutterActor>();

	PaintCallback onNeedPaint;
	ChangeEraCallback onEraChanged;
	Timer _steadyTimer;
	double get start => _start;
	double get end => _end;
	double get renderStart => _renderStart;
	double get renderEnd => _renderEnd;
	bool get isInteracting => _isInteracting;

	bool _isScaling = false;
	set isInteracting(bool value)
	{
		if(value != _isInteracting)
		{
			_isInteracting = value;
			updateSteady();
		}
	}
	set isScaling(bool value)
	{
		if(value != _isScaling)
		{
			_isScaling = value;
			updateSteady();
		}
	}

	bool _isSteady = false;

	void updateSteady()
	{
		bool isIt = !_isInteracting && !_isScaling;

		if(_steadyTimer != null)
		{
			_steadyTimer.cancel();
			_steadyTimer = null;
		}

		if(isIt)
		{
			_steadyTimer = new Timer(new Duration(seconds: 1), ()
			{
				_steadyTimer = null;
				_isSteady = true;
				startRendering();
			});
		}
		else
		{
			_isSteady = false;
			startRendering();
		}
	}

	void startRendering()
	{
		if(!_isFrameScheduled)
		{
			_isFrameScheduled = true;
			_lastFrameTime = 0.0;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
	}


	static const double LineWidth = 2.0;
	static const double LineSpacing = 10.0;
	static const double DepthOffset = LineSpacing+LineWidth;

	static const double EdgePadding = 8.0;
	static const double MoveSpeed = 40.0;
	static const double Deceleration = 3.0;
	static const double GutterLeft = 45.0;
	
	static const double EdgeRadius = 4.0;
	static const double MinChildLength = 50.0;
	static const double MarginLeft = GutterLeft + LineSpacing;
	static const double BubbleHeight = 50.0;
	static const double BubbleArrowSize = 19.0;
	static const double BubblePadding = 20.0;
	static const double AssetPadding = 30.0;
	static const double Parallax = 100.0;
	static const double AssetScreenScale = 0.3;
	static const double InitialViewportPadding = 100.0;
	static const double TravelViewportPaddingTop = 400.0;
	static const double FadeAnimationStart = BubbleHeight + BubblePadding;///2.0 + BubblePadding;

	Timeline()
	{
		setViewport(start: 1536.0, end: 3072.0);
		loadFromBundle("assets/timeline.json").then((bool success)
		{
			// Double check: Make sure we have height by now...
			//double scale = _height == 0.0 ? 1.0 : _height/(_entries.last.end-_entries.first.start);
			// We use the scale to pad by the bubble height when we set the first range.
			//setViewport(start: _entries.first.start - BubbleHeight/scale - InitialViewportPadding/scale, end: _entries.last.end + BubbleHeight/scale + InitialViewportPadding/scale, animate:true);
			setViewport(start: _entries.first.start*2.0, end: _entries.first.start, animate:true);
			advance(0.0, false);
		});
	}

	double screenPaddingInTime(double extra, double start, double end)
	{
		return (extra+BubbleHeight+InitialViewportPadding)/computeScale(start, end);
	}

	double computeScale(double start, double end)
	{
		return _height == 0.0 ? 1.0 : _height/(end-start);
	}

	TimelineEntry get nextEntry => _renderNextEntry;
	double get nextEntryOpacity => _nextEntryOpacity;

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
				if(map.containsKey("id"))
				{
					timelineEntry.id = map["id"] as String;
					_entriesById[timelineEntry.id] = timelineEntry;
				}
				if(map.containsKey("article"))
				{
					timelineEntry.articleFilename = map["article"] as String;
				}

				if(map.containsKey("asset"))
				{
					TimelineAsset asset;
					Map assetMap = map["asset"] as Map;
					String source = assetMap["source"];
					String filename = "assets/" + source;
					String extension = getExtension(source);
					switch(extension)
					{
						case "flr":
							TimelineFlare flareAsset = new TimelineFlare();
							asset = flareAsset;
							flare.FlutterActor actor = _flareResources[filename];
							if(actor == null)
							{
								actor = new flare.FlutterActor();

								bool success = await actor.loadFromBundle(filename);
								if(success)
								{
									_flareResources[filename] = actor;
								}
							}
							else
							{
								actor = actor.makeInstance();
							}
							if(actor != null)
							{
								flareAsset.actor = actor.makeInstance();
								flareAsset.animation = actor.animations[0];
								

								dynamic name = assetMap["idle"];
								if(name is String)
								{
									if((flareAsset.idle = flareAsset.actor.getAnimation(name)) != null)
									{
										flareAsset.animation = flareAsset.idle;
									}
								}

								name = assetMap["intro"];
								if(name is String)
								{
									if((flareAsset.intro = flareAsset.actor.getAnimation(name)) != null)
									{
										flareAsset.animation = flareAsset.intro;
									}
								}

								flareAsset.animationTime = 0.0;
								flareAsset.actor.advance(0.0);

								flareAsset.setupAABB = flareAsset.actor.computeAABB();
								flareAsset.animation.apply(flareAsset.animationTime, flareAsset.actor, 1.0);
								flareAsset.actor.advance(0.0);
								//print("AABB $source ${flareAsset.setupAABB}");
								//nima.Vec2D size = nima.AABB.size(new nima.Vec2D(), flareAsset.setupAABB);
								//flareAsset.width = size[0];
								//flareAsset.height = size[1];
								dynamic loop = assetMap["loop"];
								flareAsset.loop = loop is bool ? loop : true;
								dynamic offset = assetMap["offset"];
								flareAsset.offset = offset == null ? 0.0 : offset is int ? offset.toDouble() : offset;
								dynamic gap = assetMap["gap"];
								flareAsset.gap = gap == null ? 0.0 : gap is int ? gap.toDouble() : gap;
							}
							break;
						case "nma":
							TimelineNima nimaAsset = new TimelineNima();
							asset = nimaAsset;
							nima.FlutterActor actor = _nimaResources[filename];
							if(actor == null)
							{
								actor = new nima.FlutterActor();

								bool success = await actor.loadFromBundle(filename);
								if(success)
								{
									_nimaResources[filename] = actor;
								}
							}
							if(actor != null)
							{
								nimaAsset.actor = actor.makeInstance();
								nimaAsset.animation = actor.animations[0];
								nimaAsset.animationTime = 0.0;
								nimaAsset.actor.advance(0.0);
								
								nimaAsset.setupAABB = nimaAsset.actor.computeAABB();
								nimaAsset.animation.apply(nimaAsset.animationTime, nimaAsset.actor, 1.0);
								nimaAsset.actor.advance(0.0);
								//print("AABB $source ${nimaAsset.setupAABB}");
								//nima.Vec2D size = nima.AABB.size(new nima.Vec2D(), nimaAsset.setupAABB);
								//nimaAsset.width = size[0];
								//nimaAsset.height = size[1];
								dynamic loop = assetMap["loop"];
								nimaAsset.loop = loop is bool ? loop : true;
								dynamic offset = assetMap["offset"];
								nimaAsset.offset = offset == null ? 0.0 : offset is int ? offset.toDouble() : offset;
								dynamic gap = assetMap["gap"];
								nimaAsset.gap = gap == null ? 0.0 : gap is int ? gap.toDouble() : gap;

							}
							break;
							
						default:
							TimelineImage imageAsset = new TimelineImage();
							asset = imageAsset;

							ByteData data = await rootBundle.load(filename);
							Uint8List list = new Uint8List.view(data.buffer);
							ui.Codec codec = await ui.instantiateImageCodec(list);
							ui.FrameInfo frame = await codec.getNextFrame();
							imageAsset.image = frame.image;

							break;
					}

					dynamic width = assetMap["width"];
					asset.width = width is int ? width.toDouble() : width;
					dynamic height = assetMap["height"];
					asset.height = height is int ? height.toDouble() : height;
					asset.entry = timelineEntry;
					//print("ENTRY ${timelineEntry.label} $asset");
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
		TimelineEntry previous;
		for(TimelineEntry entry in allEntries)
		{
			if(previous != null)
			{
				previous.next = entry;
			}
			entry.previous = previous;
			previous = entry;

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

        // Initialize the SearchDictionary.
        SearchManager.init(allEntries);

		return true;	
	}

	TimelineEntry getById(String id)
	{
		return _entriesById[id];
	}

	void setViewport({double start = double.maxFinite, bool pad = false, double end = double.maxFinite, double height = double.maxFinite, double velocity = double.maxFinite, bool animate = false})
	{
//		print("SETVIEW $start $end");
		if(start != double.maxFinite && end != double.maxFinite)
		{
			_start = start;
			_end = end;
			if(pad)
			{
				double scale = _height/(_end-_start);
				_start = _start - (BubbleHeight+TravelViewportPaddingTop)/scale;
				_end = _end + (BubbleHeight+InitialViewportPadding)/scale;
			}
		}
		else
		{
			if(start != double.maxFinite)
			{
				double scale = height/(_end-_start);
				_start = pad ? start - (BubbleHeight+InitialViewportPadding)/scale : start;
			}
			if(end != double.maxFinite)
			{
				double scale = height/(_end-_start);
				_end = pad ? end + (BubbleHeight+InitialViewportPadding)/scale : end;
			}
		}
		if(height != double.maxFinite)
		{
			if(_height == 0.0 && _entries != null && _entries.length > 0)
			{
				double scale = height/(_end-_start);
				_start = _start - (BubbleHeight+InitialViewportPadding)/scale;
				_end = _end + (BubbleHeight+InitialViewportPadding)/scale;
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
			advance(0.0, false);
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
		if(_lastFrameTime == 0.0)
		{
			_lastFrameTime = t;
			_isFrameScheduled = true;
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
		bool stillScaling = true;
		if(!animate || ((ds*scale).abs() < 1.0 && (de*scale).abs() < 1.0))
		{
			stillScaling = false;
			_renderStart = _start;
			_renderEnd = _end;
		}
		else
		{
			doneRendering = false;
			_renderStart += ds*speed;
			_renderEnd += de*speed;
		}
		isScaling = stillScaling;

		// Update scale after changing render range.
		scale = _height/(_renderEnd-_renderStart);

		_lastEntryY = -double.maxFinite;
		_lastOnScreenEntryY = 0.0;
		_lastAssetY = -double.maxFinite;
		_labelX = 0.0;
		_offsetDepth = 0.0;
		_currentEra = null;
		_nextEntry = null;
		if(_entries != null)
		{
			if(advanceItems(_entries, MarginLeft, scale, elapsed, animate, 0))
			{
				doneRendering = false;
			}

			_renderAssets = new List<TimelineAsset>();
			if(advanceAssets(_entries, elapsed, animate, _renderAssets))
			{
				doneRendering = false;
			}
		}

		if(_nextEntryOpacity == 0.0)
		{
			_renderNextEntry = _nextEntry;
		}

		double targetNextEntryOpacity = _lastOnScreenEntryY > _height/1.7 || !_isSteady || _distanceToNextEntry < 0.01 || _nextEntry != _renderNextEntry  ? 0.0 : 1.0;
		double dt = targetNextEntryOpacity - _nextEntryOpacity;

		if(!animate || dt.abs() < 0.01)
		{
			_nextEntryOpacity = targetNextEntryOpacity;	
		}
		else
		{
			doneRendering = false;
			_nextEntryOpacity += dt * min(1.0, elapsed*10.0);
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

		if(_currentEra != _lastEra)
		{
			_lastEra = _currentEra;
			if(onEraChanged != null)
			{
				onEraChanged(_currentEra);
			}
		}

		if(_isSteady)
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
			double targetLabelY = y;

			if(targetLabelY - _lastEntryY < FadeAnimationStart 
				// The best location for our label is occluded, lets see if we can bump it forward...
				&& item.type == TimelineEntryType.Era
				&& _lastEntryY + FadeAnimationStart < endY)
			{
				
				targetLabelY = _lastEntryY + FadeAnimationStart + 0.5;
			}

			double targetLabelOpacity = targetLabelY - _lastEntryY < FadeAnimationStart ? 0.0 : 1.0;

			// Debounce labels becoming visible.
			if(targetLabelOpacity > 0.0 && item.targetLabelOpacity != 1.0)
			{
				item.delayLabel = 0.5;
			}
			item.targetLabelOpacity = targetLabelOpacity;
			if(item.delayLabel > 0.0)
			{
				targetLabelOpacity = 0.0;
				item.delayLabel -= elapsed;
			}

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
			
			double targetLabelVelocity = targetLabelY - item.labelY;
			// if(item.velocity === undefined)
			// {
			// 	item.velocity = 0.0;
			// }
			double dvy = targetLabelVelocity - item.labelVelocity;
			if(dvy.abs() > _height)
			{
				item.labelY = targetLabelY;
				item.labelVelocity = 0.0;
			}
			else
			{
				item.labelVelocity += dvy * elapsed*18.0;
				item.labelY += item.labelVelocity * elapsed*20.0;
			}
			if(animate && (item.labelVelocity.abs() > 0.01 || targetLabelVelocity.abs() > 0.01))
			{
				stillAnimating = true;
			}
			
			if(item.targetLabelOpacity > 0.0)
			{
				_lastEntryY = targetLabelY;
				if(_lastEntryY < _height && _lastEntryY > 0)
				{
					_lastOnScreenEntryY = _lastEntryY;
				}
			}

			
			if(item.type == TimelineEntryType.Era && y < 0 && endY > _height && depth > _offsetDepth)
			{
				_offsetDepth = depth.toDouble();
			}
			if(item.type == TimelineEntryType.Era && y < 0 && endY > _height/2.0)
			{
				_currentEra = item;
			}

			if(y > _height + BubbleHeight)
			{
				item.labelY = y;
				if(_nextEntry == null)
				{
					_nextEntry = item;
					_distanceToNextEntry = (y - _height)/_height;
				}
				//continue;
			}
			else if(endY < -BubbleHeight)
			{
				item.labelY = y;
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

	bool advanceAssets(List<TimelineEntry> items, double elapsed, bool animate, List<TimelineAsset> renderAssets)
	{
		bool stillAnimating = false;
		for(TimelineEntry item in items)
		{
			if(item.asset != null)
			{
				double y = item.labelY;
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

				TimelineAsset asset = item.asset;
				if(asset.opacity == 0.0)
				{
					// Item was invisible, just pop it to the right place and stop velocity.
					asset.y = targetAssetY;
					asset.velocity = 0.0;
				}
				double da = targetAssetOpacity - asset.opacity;
				if(!animate || da.abs() < 0.01)
				{
					asset.opacity = targetAssetOpacity;	
				}
				else
				{
					stillAnimating = true;
					asset.opacity += da * min(1.0, elapsed*15.0);
				}

				if(asset.opacity > 0.0) // visible
				{
					// if(asset.y === undefined)
					// {
					// 	asset.y = Math.max(this._lastAssetY, targetAssetY);
					// }
					
					double targetAssetVelocity = max(_lastAssetY, targetAssetY) - asset.y;
					double dvay = targetAssetVelocity - asset.velocity;
					if(dvay.abs() > _height)
					{
						asset.y = targetAssetY;
						asset.velocity = 0.0;
					}
					else
					{
						asset.velocity += dvay * elapsed*15.0;
						asset.y += asset.velocity * elapsed*17.0;
					}
					if(asset.velocity.abs() > 0.01 || targetAssetVelocity.abs() > 0.01)
					{
						stillAnimating = true;
					}

					_lastAssetY = /*assetY*/targetAssetY + asset.height * AssetScreenScale /*renderScale(asset.scale)*/ + AssetPadding;
					if(asset is TimelineNima)
					{
						_lastAssetY += asset.gap;
					}
					else if(asset is TimelineFlare)
					{
						_lastAssetY += asset.gap;
					}
					if(asset.y > _height || asset.y + asset.height * AssetScreenScale < 0.0)
					{
						// Cull it, it's not in view. Make sure we don't advance animations.
						if(asset is TimelineNima)
						{
							TimelineNima nimaAsset = asset;
							if(!nimaAsset.loop)
							{
								nimaAsset.animationTime = -1.0;
							}
						}
						else if(asset is TimelineFlare)
						{
							TimelineFlare flareAsset = asset;
							if(!flareAsset.loop)
							{
								flareAsset.animationTime = -1.0;
							}
							else if(flareAsset.intro != null)
							{
								flareAsset.animationTime = -1.0;
								flareAsset.animation = flareAsset.intro;
							}
						}
					}
					else
					{
						if(asset is TimelineNima && isActive)
						{
							asset.animationTime += elapsed;
							if(asset.loop)
							{
								asset.animationTime %= asset.animation.duration;
							}
							asset.animation.apply(asset.animationTime, asset.actor, 1.0);
							asset.actor.advance(elapsed);
							stillAnimating = true;
						}
						else if(asset is TimelineFlare && isActive)
						{
							asset.animationTime += elapsed;
							if(asset.intro == asset.animation && asset.animationTime >= asset.animation.duration)
							{
								asset.animationTime -= asset.animation.duration;
								asset.animation = asset.idle;
							}
							if(asset.loop && asset.animationTime > 0)
							{
								asset.animationTime %= asset.animation.duration;
							}
							asset.animation.apply(asset.animationTime, asset.actor, 1.0);
							asset.actor.advance(elapsed);
							stillAnimating = true;
						}

						renderAssets.add(item.asset);
					}
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