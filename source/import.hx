#if !macro
//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

import backend.Paths;
import backend.Controls;
import backend.CoolUtil;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.CustomFadeTransition;
import backend.ClientPrefs;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.Mods;
import backend.Language;

import backend.ui.*; //Psych-UI

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;
import states.LoadingState;

#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

//flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

#if DISCORD_ALLOWED
import meta.data.Discord;
#end

import hxvlc.flixel.*;

import meta.data.Paths;
import meta.data.ClientPrefs;
import meta.data.Conductor;
import meta.data.CoolUtil;
import meta.data.Highscore;

import meta.states.*;

import gameObjects.BGSprite;

import meta.states.KUTValueHandler;

import meta.data.ExUtils;
import meta.data.ExUtils.addShader as ApplyShaderToCamera;
import meta.data.ExUtils.removeShader as RemoveShaderFromCamera;
import meta.data.ExUtils.insertFlxCamera as insertFlxCamera;

using StringTools;
using meta.FlxObjectTools;
#end
