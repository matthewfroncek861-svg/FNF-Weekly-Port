package;

#if android
import android.content.Context;
#end

import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

import backend.Highscore;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = Init; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = false; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPSCounter;
	public static var compilationInformation:TextField;
	
	public static var scaleMode:FunkinRatioScaleMode;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		#if (cpp && windows)
		backend.Native.fixScaling();
		#end

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}
	public static function setScaleMode(scale:String){
		switch(scale){
			default:
				Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
			case 'EXACT_FIT':
				Lib.current.stage.scaleMode = StageScaleMode.EXACT_FIT;
			case 'NO_BORDER':
				Lib.current.stage.scaleMode = StageScaleMode.NO_BORDER;
			case 'SHOW_ALL':
				Lib.current.stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		// #if !debug
		// #if HIT_SINGLE
		// initialState = meta.states.HitSingleInit;
		// #else
		// initialState = TitleState;		
		// #end
		// #end

		ClientPrefs.loadDefaultKeys();
		addChild(new FNFGame(gameWidth, gameHeight, initialState, #if(flixel < "5.0.0")zoom,#end framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end
		
		// #if !DEBUG_MODE
		// 	compilationInformation = new TextField();
		// 	compilationInformation.height = FlxG.stage.stageHeight/2;
		// 	compilationInformation.width = FlxG.stage.stageWidth;
		// 	compilationInformation.defaultTextFormat = new TextFormat('_sans', 48, FlxColor.WHITE, null, null, null, null, null, openfl.text.TextFormatAlign.CENTER);
		// 	compilationInformation.text = Date.now().toString() + '\n' + Sys.environment()["USERNAME"].trim();
		// 	compilationInformation.alpha = 0.675;
		// 	addChild(compilationInformation);
		// #end


		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.signals.gameResized.add(onResize);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();





	}
	private static function onStateSwitch() {
		scaleMode.resetSize();
	}


	static function onResize(w,h) 
	{
		final scale:Float = Math.max(1,Math.min(w / FlxG.width, h / FlxG.height));
		if (fpsVar != null) {
			fpsVar.scaleX = fpsVar.scaleY = scale;
		}
		// if (compilationInformation!=null) {

		// 	compilationInformation.scaleX = compilationInformation.scaleY = Math.max(1,scale);
		// 	compilationInformation.height = h;
		// 	compilationInformation.width = w;
		// 	compilationInformation.y = h/2;
		// }

		@:privateAccess if (FlxG.cameras != null) for (i in FlxG.cameras.list) if (i != null && i._filters != null) resetSpriteCache(i.flashSprite);
		if (FlxG.game != null) resetSpriteCache(FlxG.game);
		
	}	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		// #if !debug
		// #if HIT_SINGLE
		// initialState = meta.states.HitSingleInit;
		// #else
		// initialState = TitleState;		
		// #end
		// #end

		ClientPrefs.loadDefaultKeys();
		addChild(new FNFGame(gameWidth, gameHeight, initialState, #if(flixel < "5.0.0")zoom,#end framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end
		
		// #if !DEBUG_MODE
		// 	compilationInformation = new TextField();
		// 	compilationInformation.height = FlxG.stage.stageHeight/2;
		// 	compilationInformation.width = FlxG.stage.stageWidth;
		// 	compilationInformation.defaultTextFormat = new TextFormat('_sans', 48, FlxColor.WHITE, null, null, null, null, null, openfl.text.TextFormatAlign.CENTER);
		// 	compilationInformation.text = Date.now().toString() + '\n' + Sys.environment()["USERNAME"].trim();
		// 	compilationInformation.alpha = 0.675;
		// 	addChild(compilationInformation);
		// #end


		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.signals.gameResized.add(onResize);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();





	}
	private static function onStateSwitch() {
		scaleMode.resetSize();
	}


	static function onResize(w,h) 
	{
		final scale:Float = Math.max(1,Math.min(w / FlxG.width, h / FlxG.height));
		if (fpsVar != null) {
			fpsVar.scaleX = fpsVar.scaleY = scale;
		}
		// if (compilationInformation!=null) {

		// 	compilationInformation.scaleX = compilationInformation.scaleY = Math.max(1,scale);
		// 	compilationInformation.height = h;
		// 	compilationInformation.width = w;
		// 	compilationInformation.y = h/2;
		// }

		@:privateAccess if (FlxG.cameras != null) for (i in FlxG.cameras.list) if (i != null && i._filters != null) resetSpriteCache(i.flashSprite);
		if (FlxG.game != null) resetSpriteCache(FlxG.game);
		
	}
	public static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess 
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}

class FNFGame extends FlxGame
{
	private static function crashGame() {
		null
		.draw();
	}

/**
* Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
*/
	override function create(_):Void {
		try
			super.create(_)
		catch (e)
			onCrash(e);
	}

	override function onFocus(_):Void {
		try
			super.onFocus(_)
		catch (e)
			onCrash(e);
	}

	override function onFocusLost(_):Void {
		try
			super.onFocusLost(_)
		catch (e)
			onCrash(e);
	}

	/**
	* Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	*/
	override function onEnterFrame(_):Void {
		try
			super.onEnterFrame(_)
		catch (e)
			onCrash(e);
	}

	/**
	* This function is called by `step()` and updates the actual game state.
	* May be called multiple times per "frame" or draw call.
	*/
	override function update():Void {
		#if CRASH_TEST
		if (FlxG.keys.justPressed.F9)
			crashGame();
		#end
		try
			super.update()
		catch (e)
			onCrash(e);
	}

	/**
	* Goes through the game state and draws all the game objects and special effects.
	*/
	override function draw():Void {
		try
			super.draw()
		catch (e)
			onCrash(e);
	}

	private final function onCrash(e:haxe.Exception):Void {
		var emsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					emsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					trace(stackItem);
			}
		}

		FlxG.switchState(new meta.states.substate.CrashReportSubstate(FlxG.state, emsg, e.message));
	}
}
