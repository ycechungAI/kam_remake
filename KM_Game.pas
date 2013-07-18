unit KM_Game;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, FileUtil, {$ENDIF}
  Forms, Controls, Classes, Dialogs, ExtCtrls, SysUtils, KromUtils, Math, TypInfo,
  {$IFDEF USE_MAD_EXCEPT} MadExcept, KM_Exceptions, {$ENDIF}
  KM_CommonTypes, KM_Defaults, KM_Points,
  KM_Alerts, KM_GameInputProcess, KM_GameOptions,
  KM_InterfaceDefaults, KM_InterfaceMapEditor, KM_InterfaceGamePlay,
  KM_MapEditor, KM_Minimap, KM_Networking,
  KM_PathFinding, KM_PathFindingAStarOld, KM_PathFindingAStarNew, KM_PathFindingJPS,
  KM_PerfLog, KM_Projectiles, KM_Render, KM_Viewport, KM_ResTexts;

type
  TGameMode = (
    gmSingle,
    gmMulti,        //Different GIP, networking,
    gmMapEd,        //Army handling, lite updates,
    gmReplaySingle, //No input, different results screen to gmReplayMulti
    gmReplayMulti   //No input, different results screen to gmReplaySingle
    );

  //Class that manages single game session
  TKMGame = class
  private //Irrelevant to savegame
    fTimerGame: TTimer;
    fAlerts: TKMAlerts;
    fGameOptions: TKMGameOptions;
    fNetworking: TKMNetworking;
    fGameInputProcess: TGameInputProcess;
    fTextMission: TKMTextLibraryMulti;
    fMinimap: TKMMinimap;
    fPathfinding: TPathFinding;
    fViewport: TViewport;
    fPerfLog: TKMPerfLog;
    fActiveInterface: TKMUserInterface; //Shortcut for both of UI
    fGamePlayInterface: TKMGamePlayInterface;
    fMapEditorInterface: TKMapEdInterface;
    fMapEditor: TKMMapEditor;

    fIsExiting: Boolean; //Set this to true on Exit and unit/house pointers will be released without cross-checking
    fIsPaused: Boolean;
    fGameSpeed: Single; //Actual speedup value
    fGameSpeedMultiplier: Word; //How many ticks are compressed into one
    fGameMode: TGameMode;
    fWaitingForNetwork: Boolean;
    fAdvanceFrame: Boolean; //Replay variable to advance 1 frame, afterwards set to false
    fSaveFile: string;  //Relative pathname to savegame we are playing, so it gets saved to crashreport
    fShowTeamNames: Boolean;
    fGameLockedMutex: Boolean;

  //Should be saved
    fCampaignMap: Byte;         //Which campaign map it is, so we can unlock next one on victory
    fCampaignName: string;  //Is this a game part of some campaign
    fGameName: string;
    fGameTickCount: Cardinal;
    fUIDTracker: Cardinal;       //Units-Houses tracker, to issue unique IDs
    fMissionFile: string;   //Relative pathname to mission we are playing, so it gets saved to crashreport
    fMissionMode: TKMissionMode;

    procedure GameMPDisconnect(const aData: UnicodeString);
    procedure MultiplayerRig;
    procedure SaveGame(const aPathName: string);
    procedure UpdatePeaceTime;
    procedure SyncUI;
  public
    PlayOnState: TGameResultMsg;
    DoGameHold: Boolean; //Request to run GameHold after UpdateState has finished
    DoGameHoldState: TGameResultMsg; //The type of GameHold we want to occur due to DoGameHold
    SkipReplayEndCheck: Boolean;

    ///	<param name="aRender">
    ///	  Pointer to Render class, that will execute our rendering requests
    ///	  performed via RenderPool we create.
    ///	</param>
    ///	<param name="aNetworking">
    ///	  Pointer to networking class, required if this is a multiplayer game.
    ///	</param>
    constructor Create(aGameMode: TGameMode; aRender: TRender; aNetworking: TKMNetworking);
    destructor Destroy; override;

    procedure KeyDown(Key: Word; Shift: TShiftState);
    procedure KeyPress(Key: Char);
    procedure KeyUp(Key: Word; Shift: TShiftState);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer);

    procedure GameStart(aMissionFile, aGameName, aCampName: string; aCampMap: Byte; aLocation: ShortInt; aColor: Cardinal); overload;
    procedure GameStart(aSizeX, aSizeY: Integer); overload;
    procedure Load(const aPathName: string);

    function MapX: Word;
    function MapY: Word;

    procedure Resize(X,Y: Integer);

    procedure GameMPPlay(Sender:TObject);
    procedure GameMPReadyToPlay(Sender:TObject);
    procedure GameHold(DoHold:boolean; Msg:TGameResultMsg); //Hold the game to ask if player wants to play after Victory/Defeat/ReplayEnd
    procedure RequestGameHold(Msg:TGameResultMsg);
    procedure PlayerVictory(aPlayerIndex:TPlayerIndex);
    procedure PlayerDefeat(aPlayerIndex:TPlayerIndex);
    procedure GameWaitingForNetwork(aWaiting:boolean);
    procedure GameDropWaitingPlayers;

    procedure AutoSave;
    procedure SaveMapEditor(const aPathName: string);
    procedure RestartReplay; //Restart the replay but keep current viewport position/zoom

    function MissionTime: TDateTime;
    function GetPeacetimeRemaining: TDateTime;
    function CheckTime(aTimeTicks: Cardinal): Boolean;
    function IsPeaceTime: Boolean;
    function IsMapEditor: Boolean;
    function IsMultiplayer: Boolean;
    function IsReplay: Boolean;
    procedure ShowMessage(aKind: TKMMessageKind; aText: string; aLoc: TKMPoint);
    procedure ShowMessageFormatted(aKind: TKMMessageKind; aText: string; aLoc: TKMPoint; aParams: array of const);
    procedure ShowOverlay(aText: string);
    procedure ShowOverlayFormatted(aText: string; aParams: array of const);
    procedure OverlayAppend(aText: string);
    procedure OverlayAppendFormatted(aText: string; aParams: array of const);
    property GameTickCount:cardinal read fGameTickCount;
    property GameName: string read fGameName;
    property CampaignName: string read fCampaignName;
    property CampaignMap: Byte read fCampaignMap;
    property GameSpeed: Single read fGameSpeed;
    function PlayerLoc: Byte;
    function PlayerColor: Cardinal;

    property GameMode: TGameMode read fGameMode;
    property MissionFile: string read fMissionFile;
    property SaveFile: string read fSaveFile;
    property ShowTeamNames: Boolean read fShowTeamNames write fShowTeamNames;

    property IsExiting: Boolean read fIsExiting;
    property IsPaused: Boolean read fIsPaused write fIsPaused;
    property MissionMode: TKMissionMode read fMissionMode write fMissionMode;
    function GetNewUID: Integer;
    procedure SetGameSpeed(aSpeed: Single; aToggle: Boolean);
    procedure StepOneFrame;
    function SaveName(const aName, aExt: string; aMultiPlayer: Boolean): string;
    procedure UpdateMultiplayerTeams;

    property PerfLog: TKMPerfLog read fPerfLog;
    procedure UpdateGameCursor(X,Y: Integer; Shift: TShiftState);

    property Alerts: TKMAlerts read fAlerts;
    property Minimap: TKMMinimap read fMinimap;
    property Networking: TKMNetworking read fNetworking;
    property Pathfinding: TPathFinding read fPathfinding;
    property GameInputProcess: TGameInputProcess read fGameInputProcess;
    property GameOptions: TKMGameOptions read fGameOptions;
    property GamePlayInterface: TKMGamePlayInterface read fGamePlayInterface;
    property MapEditorInterface: TKMapEdInterface read fMapEditorInterface;
    property MapEditor: TKMMapEditor read fMapEditor;
    property Viewport: TViewport read fViewport;

    procedure Save(const aName: string);
    {$IFDEF USE_MAD_EXCEPT}
    procedure AttachCrashReport(const ExceptIntf: IMEException; aZipFile: string);
    {$ENDIF}
    procedure ReplayInconsistancy;

    procedure Render(aRender: TRender);
    procedure RenderSelection;
    procedure UpdateGame(Sender: TObject);
    procedure UpdateState(aGlobalTickCount: Cardinal);
    procedure UpdateStateIdle(aFrameTime: Cardinal);
  end;


var
  fGame: TKMGame;


implementation
uses
  KM_CommonClasses, KM_Log, KM_Utils, KM_GameCursor,
  KM_ArmyEvaluation, KM_GameApp, KM_GameInfo, KM_MissionScript, KM_MissionScript_Standard,
  KM_Player, KM_PlayerSpectator, KM_PlayersCollection, KM_RenderPool, KM_Resource, KM_ResCursors,
  KM_ResSound, KM_Terrain, KM_TerrainPainter, KM_AIFields, KM_Maps, KM_Sound,
  KM_Scripting, KM_GameInputProcess_Single, KM_GameInputProcess_Multi, KM_Main;


{ Creating everything needed for MainMenu, game stuff is created on StartGame }
//aMultiplayer - is this a multiplayer game
//aRender - who will be rendering the Game session
constructor TKMGame.Create(aGameMode: TGameMode; aRender: TRender; aNetworking: TKMNetworking);
begin
  inherited Create;

  fGameMode := aGameMode;
  fNetworking := aNetworking;

  fAdvanceFrame := False;
  fUIDTracker    := 0;
  PlayOnState   := gr_Cancel;
  DoGameHold    := False;
  SkipReplayEndCheck := False;
  fWaitingForNetwork := False;
  fGameOptions  := TKMGameOptions.Create;

  //Create required UI (gameplay or MapEd)
  if fGameMode = gmMapEd then
  begin
    fMinimap := TKMMinimap.Create(False, True, False);
    fMapEditorInterface := TKMapEdInterface.Create(aRender.ScreenX, aRender.ScreenY);
    fActiveInterface := fMapEditorInterface;
  end
  else
  begin
    fMinimap := TKMMinimap.Create(False, False, False);
    fGamePlayInterface := TKMGamePlayInterface.Create(aRender.ScreenX, aRender.ScreenY, IsMultiplayer, IsReplay);
    fActiveInterface := fGamePlayInterface;
  end;

  //todo: Maybe we should reset the GameCursor? If I play 192x192 map, quit, and play a 64x64 map
  //      my cursor could be at (190,190) if the player starts with his cursor over the controls panel...
  //      This caused a crash in RenderCursors which I fixed by adding range checking to CheckTileRevelation
  //      (good idea anyway) There could be other crashes caused by this.
  fViewport := TViewport.Create(aRender.ScreenX, aRender.ScreenY);

  fTimerGame := TTimer.Create(nil);
  SetGameSpeed(1, False); //Initialize relevant variables
  fTimerGame.OnTimer := UpdateGame;
  fTimerGame.Enabled := True;

  //Here comes terrain/mission init
  SetKaMSeed(4); //Every time the game will be the same as previous. Good for debug.
  gTerrain := TKMTerrain.Create;
  gPlayers := TKMPlayersCollection.Create;
  fAIFields := TKMAIFields.Create;

  InitUnitStatEvals; //Army

  if DO_PERF_LOGGING then fPerfLog := TKMPerfLog.Create;
  gLog.AddTime('<== Game creation is done ==>');
  fAlerts := TKMAlerts.Create(@fGameTickCount, fViewport);
  fScripting := TKMScripting.Create;

  case PathFinderToUse of
    0:  fPathfinding := TPathfindingAStarOld.Create;
    1:  fPathfinding := TPathfindingAStarNew.Create;
    2:  fPathfinding := TPathfindingJPS.Create;
  else  fPathfinding := TPathfindingAStarOld.Create;

  end;
  gProjectiles := TKMProjectiles.Create;

  fRenderPool := TRenderPool.Create(aRender);

  fGameTickCount := 0; //Restart counter
end;


{ Destroy what was created }
destructor TKMGame.Destroy;
begin
  //We might have crashed part way through .Create, so we can't assume ANYTHING exists here.
  //Doing so causes a 2nd exception which overrides 1st. Hence check <> nil on everything except Frees, TObject.Free does that already.

  if fGameLockedMutex then fMain.UnlockMutex;
  if fTimerGame <> nil then fTimerGame.Enabled := False;
  fIsExiting := True;

  //if (fGameInputProcess <> nil) and (fGameInputProcess.ReplayState = gipRecording) then
  //  fGameInputProcess.SaveToFile(SaveName('basesave', 'rpl', fGameMode = gmMulti));

  if DO_PERF_LOGGING and (fPerfLog <> nil) then fPerfLog.SaveToFile(ExeDir + 'Logs'+PathDelim+'PerfLog.txt');

  FreeAndNil(fTimerGame);

  FreeThenNil(fMapEditor);
  FreeThenNil(gPlayers);
  FreeThenNil(fTerrainPainter);
  FreeThenNil(gTerrain);
  FreeAndNil(fAIFields);
  FreeAndNil(gProjectiles);
  FreeAndNil(fPathfinding);
  FreeAndNil(fScripting);
  FreeAndNil(fAlerts);

  FreeThenNil(fGamePlayInterface);
  FreeThenNil(fMapEditorInterface);
  FreeAndNil(fMinimap);
  FreeAndNil(fViewport);

  FreeAndNil(fGameInputProcess);
  FreeAndNil(fRenderPool);
  FreeAndNil(fGameOptions);
  FreeAndNil(fAlerts);
  if DO_PERF_LOGGING then fPerfLog.Free;

  //When leaving the game we should always reset the cursor in case the user had beacon or linking selected
  fResource.Cursors.Cursor := kmc_Default;

  FreeAndNil(MySpectator);

  inherited;
end;


procedure TKMGame.Resize(X,Y: Integer);
begin
  fActiveInterface.Resize(X, Y);

  fViewport.Resize(X, Y);
end;


function TKMGame.MapX: Word;
begin
  Result := gTerrain.MapX;
end;


function TKMGame.MapY: Word;
begin
  Result := gTerrain.MapY;
end;


procedure TKMGame.KeyDown(Key: Word; Shift: TShiftState);
begin
  fActiveInterface.KeyDown(Key, Shift);
end;


procedure TKMGame.KeyPress(Key: Char);
begin
  fActiveInterface.KeyPress(Key);
end;


procedure TKMGame.KeyUp(Key: Word; Shift: TShiftState);
begin
  fActiveInterface.KeyUp(Key, Shift);
end;


procedure TKMGame.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  fActiveInterface.MouseDown(Button,Shift,X,Y);
end;


procedure TKMGame.MouseMove(Shift: TShiftState; X,Y: Integer);
begin
  fActiveInterface.MouseMove(Shift, X,Y);
end;


procedure TKMGame.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  fActiveInterface.MouseUp(Button, Shift, X,Y);
end;


procedure TKMGame.MouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
var PrevCursor: TKMPointF;
begin
  fActiveInterface.MouseWheel(Shift, WheelDelta, X, Y);

  if (X < 0) or (Y < 0) then Exit; //This occours when you use the mouse wheel on the window frame

  //Allow to zoom only when curor is over map. Controls handle zoom on their own
  if (fActiveInterface.MyControls.CtrlOver = nil) then
  begin
    UpdateGameCursor(X, Y, Shift); //Make sure we have the correct cursor position to begin with
    PrevCursor := GameCursor.Float;
    fViewport.Zoom := fViewport.Zoom + WheelDelta / 2000;
    UpdateGameCursor(X, Y, Shift); //Zooming changes the cursor position
    //Move the center of the screen so the cursor stays on the same tile, thus pivoting the zoom around the cursor
    fViewport.Position := KMPointF(fViewport.Position.X + PrevCursor.X-GameCursor.Float.X,
                                   fViewport.Position.Y + PrevCursor.Y-GameCursor.Float.Y);
    UpdateGameCursor(X, Y, Shift); //Recentering the map changes the cursor position
  end;
end;


//New mission
procedure TKMGame.GameStart(aMissionFile, aGameName, aCampName: string; aCampMap: Byte; aLocation: ShortInt; aColor: Cardinal);
const
  GAME_PARSE: array [TGameMode] of TMissionParsingMode = (
    mpm_Single, mpm_Multi, mpm_Editor, mpm_Single, mpm_Single);
var
  I: Integer;
  ParseMode: TMissionParsingMode;
  PlayerEnabled: TPlayerEnabledArray;
  Parser: TMissionParserStandard;
begin
  gLog.AddTime('GameStart');
  Assert(fGameMode in [gmMulti, gmMapEd, gmSingle]);

  fGameName := aGameName;
  fCampaignName := aCampName;
  fCampaignMap := aCampMap;
  fMissionFile := ExtractRelativePath(ExeDir, aMissionFile);
  fSaveFile := '';
  MySpectator := nil; //In case somebody looks at it while parsing DAT, e.g. destroyed houses

  gLog.AddTime('Loading DAT file: ' + aMissionFile);

  //Disable players in MP to skip their assets from loading by MissionParser
  //In SP all players are enabled by default
  case fGameMode of
    gmMulti:  begin
                FillChar(PlayerEnabled, SizeOf(PlayerEnabled), #0);
                for I := 1 to fNetworking.NetPlayers.Count do
                  //PlayerID is 0 based
                  PlayerEnabled[fNetworking.NetPlayers[I].StartLocation - 1] := True;

                //Fixed AIs are always enabled (e.g. coop missions)
                for I := 0 to fNetworking.MapInfo.LocCount-1 do
                  if fNetworking.MapInfo.CanBeAI[I] and not fNetworking.MapInfo.CanBeHuman[I] then
                    PlayerEnabled[I] := True;
              end;
    gmSingle: //Setup should tell us which player is AI and which not
              for I := 0 to MAX_PLAYERS - 1 do
                PlayerEnabled[I] := True;
    else      FillChar(PlayerEnabled, SizeOf(PlayerEnabled), #255);
  end;

  //Choose how we will parse the script
  ParseMode := GAME_PARSE[fGameMode];

  if fGameMode = gmMapEd then
  begin
    //Mission loader needs to read the data into MapEd (e.g. FOW revealers)
    fMapEditor := TKMMapEditor.Create;
    fTerrainPainter := TKMTerrainPainter.Create;
  end;

  Parser := TMissionParserStandard.Create(ParseMode, PlayerEnabled, False);
  try
    if not Parser.LoadMission(aMissionFile) then
      raise Exception.Create(Parser.FatalErrors);

    if fGameMode = gmMapEd then
    begin
      gPlayers.AddPlayers(MAX_PLAYERS - gPlayers.Count); //Activate all players
      for I := 0 to gPlayers.Count - 1 do
        gPlayers[I].FogOfWar.RevealEverything;
      MySpectator := TKMSpectator.Create(0);
      MySpectator.FOWIndex := PLAYER_NONE;
    end
    else
    if fGameMode = gmSingle then
    begin
      for I := 0 to gPlayers.Count - 1 do
        gPlayers[I].PlayerType := pt_Computer;

      //-1 means automatically detect the location (used for tutorials and campaigns)
      if aLocation = -1 then
        aLocation := Parser.DefaultLocation;

      Assert(InRange(aLocation, 0, gPlayers.Count - 1), 'No human player detected');
      gPlayers[aLocation].PlayerType := pt_Human;
      MySpectator := TKMSpectator.Create(aLocation);
      if aColor <> $00000000 then //If no color specified use default from mission file (don't overwrite it)
        gPlayers[MySpectator.PlayerIndex].FlagColor := aColor;
    end;

    if (Parser.MinorErrors <> '') and (fGameMode <> gmMapEd) then
      fGamePlayInterface.MessageIssue(mkQuill, 'Warnings in mission script:|' + Parser.MinorErrors);

    if (Parser.MinorErrors <> '') and (fGameMode = gmMapEd) then
      fMapEditorInterface.ShowMessage('Warnings in mission script:|' + Parser.MinorErrors);
  finally
    Parser.Free;
  end;

  if fGameMode <> gmMapEd then
  begin
    fScripting.LoadFromFile(ChangeFileExt(aMissionFile, '.script'));
    if (fScripting.ErrorString <> '') then
      fGamePlayInterface.MessageIssue(mkQuill, 'Warnings in script:|' + fScripting.ErrorString);
  end;


  case fGameMode of
    gmMulti:  begin
                fGameInputProcess := TGameInputProcess_Multi.Create(gipRecording, fNetworking);
                fTextMission := TKMTextLibraryMulti.Create;
                fTextMission.LoadLocale(ChangeFileExt(aMissionFile, '.%s.libx'));
              end;
    gmSingle: begin
                fGameInputProcess := TGameInputProcess_Single.Create(gipRecording);
                fTextMission := TKMTextLibraryMulti.Create;
                fTextMission.LoadLocale(ChangeFileExt(aMissionFile, '.%s.libx'));
              end;
    gmMapEd:  ;
  end;

  gLog.AddTime('Gameplay recording initialized', True);

  if fGameMode = gmMulti then
    MultiplayerRig;

  gPlayers.AfterMissionInit(True);

  SetKaMSeed(4); //Random after StartGame and ViewReplay should match

  //We need to make basesave.bas since we don't know the savegame name
  //until after user saves it, but we need to attach replay base to it.
  //Basesave is sort of temp we save to HDD instead of keeping in RAM
  if fGameMode in [gmSingle, gmMulti] then
    SaveGame(SaveName('basesave', 'bas', IsMultiplayer));

  //MissionStart goes after basesave to keep it pure (repeats on Load of basesave)
  fScripting.ProcMissionStart;

  //When everything is ready we can update UI
  SyncUI;
  fViewport.Position := KMPointF(gPlayers[MySpectator.PlayerIndex].CenterScreen);

  gLog.AddTime('Gameplay initialized', true);
end;


//All setup data gets taken from fNetworking class
procedure TKMGame.MultiplayerRig;
var
  I: Integer;
  PlayerIndex: TPlayerIndex;
begin
  //Copy game options from lobby to this game
  fGameOptions.Peacetime := fNetworking.NetGameOptions.Peacetime;
  fGameOptions.SpeedPT := fNetworking.NetGameOptions.SpeedPT;
  fGameOptions.SpeedAfterPT := fNetworking.NetGameOptions.SpeedAfterPT;

  if IsPeaceTime then
    SetGameSpeed(fGameOptions.SpeedPT, False)
  else
    SetGameSpeed(fGameOptions.SpeedAfterPT, False);

  //First give all AI players a name so fixed AIs (not added in lobby) still have a name
  for I := 0 to gPlayers.Count-1 do
    if gPlayers[I].PlayerType = pt_Computer then
      //Can't be translated yet because PlayerName is written into save (solve this when we make network messages translated?)
      gPlayers[I].PlayerName := 'AI Player';


  //Assign existing NetPlayers(1..N) to map players(0..N-1)
  for I := 1 to fNetworking.NetPlayers.Count do
  begin
    PlayerIndex := fNetworking.NetPlayers[I].StartLocation - 1; //PlayerID is 0 based
    gPlayers[PlayerIndex].PlayerType := fNetworking.NetPlayers[I].GetPlayerType;
    gPlayers[PlayerIndex].PlayerName := fNetworking.NetPlayers[I].Nikname;
    gPlayers[PlayerIndex].FlagColor := fNetworking.NetPlayers[I].FlagColor;
  end;

  //Setup alliances
  //We mirror Lobby team setup on to alliances. Savegame and coop has the setup already
  if (fNetworking.SelectGameKind = ngk_Map) and not fNetworking.MapInfo.IsCoop then
    UpdateMultiplayerTeams;

  MySpectator := TKMSpectator.Create(fNetworking.NetPlayers[fNetworking.MyIndex].StartLocation-1);

  //We cannot remove a player from a save (as they might be interacting with other players)

  gPlayers.SyncFogOfWar; //Syncs fog of war revelation between players AFTER alliances
  //Multiplayer missions don't have goals yet, so add the defaults (except for special/coop missions)
  if (fNetworking.SelectGameKind = ngk_Map)
  and not fNetworking.MapInfo.IsSpecial and not fNetworking.MapInfo.IsCoop then
    gPlayers.AddDefaultGoalsToAll(fMissionMode);

  fNetworking.OnPlay           := GameMPPlay;
  fNetworking.OnReadyToPlay    := GameMPReadyToPlay;
  fNetworking.OnCommands       := TGameInputProcess_Multi(fGameInputProcess).RecieveCommands;
  fNetworking.OnTextMessage    := fGamePlayInterface.ChatMessage;
  fNetworking.OnPlayersSetup   := fGamePlayInterface.AlliesOnPlayerSetup;
  fNetworking.OnPingInfo       := fGamePlayInterface.AlliesOnPingInfo;
  fNetworking.OnDisconnect     := GameMPDisconnect; //For auto reconnecting
  fNetworking.OnReassignedHost := nil; //So it is no longer assigned to a lobby event
  fNetworking.GameCreated;

  if fNetworking.Connected and (fNetworking.NetGameState = lgs_Loading) then GameWaitingForNetwork(True); //Waiting for players
end;


procedure TKMGame.UpdateMultiplayerTeams;
var
  I, K: Integer;
  PlayerI: TKMPlayer;
  PlayerK: Integer;
begin
  for I := 1 to fNetworking.NetPlayers.Count do
  begin
    PlayerI := gPlayers[fNetworking.NetPlayers[I].StartLocation - 1]; //PlayerID is 0 based
    for K := 1 to fNetworking.NetPlayers.Count do
    begin
      PlayerK := fNetworking.NetPlayers[K].StartLocation - 1; //PlayerID is 0 based

      //Players are allies if they belong to same team (team 0 means free-for-all)
      if (fNetworking.NetPlayers[I].Team <> 0)
      and (fNetworking.NetPlayers[I].Team = fNetworking.NetPlayers[K].Team) then
        PlayerI.Alliances[PlayerK] := at_Ally
      else
        PlayerI.Alliances[PlayerK] := at_Enemy;
    end;
  end;
end;


//Everyone is ready to start playing
//Issued by fNetworking at the time depending on each Players lag individually
procedure TKMGame.GameMPPlay(Sender:TObject);
begin
  GameWaitingForNetwork(false); //Finished waiting for players
  fNetworking.AnnounceGameInfo(MissionTime, GameName);
  gLog.AddTime('Net game began');
end;


procedure TKMGame.GameMPReadyToPlay(Sender:TObject);
begin
  //Update the list of players that are ready to play
  GameWaitingForNetwork(true);
end;


procedure TKMGame.GameMPDisconnect(const aData: UnicodeString);
begin
  if fNetworking.NetGameState in [lgs_Game, lgs_Reconnecting] then
  begin
    if WRITE_RECONNECT_LOG then gLog.AddTime('GameMPDisconnect: '+aData);
    fNetworking.PostLocalMessage('Connection failed: '+aData,false); //Debugging that should be removed later
    fNetworking.OnJoinFail := GameMPDisconnect; //If the connection fails (e.g. timeout) then try again
    fNetworking.OnJoinAssignedHost := nil;
    fNetworking.OnJoinSucc := nil;
    fNetworking.AttemptReconnection;
  end
  else
  begin
    fNetworking.Disconnect;
    fGameApp.Stop(gr_Disconnect, gResTexts[TX_GAME_ERROR_NETWORK] + ' ' + aData)
  end;
end;


{$IFDEF USE_MAD_EXCEPT}
procedure TKMGame.AttachCrashReport(const ExceptIntf: IMEException; aZipFile:string);

  procedure AttachFile(const aFile: string);
  begin
    if (aFile = '') or not FileExists(aFile) then Exit;
    ExceptIntf.AdditionalAttachments.Add(aFile, '', aZipFile);
  end;

var I: Integer;
begin
  gLog.AddTime('Creating crash report...');

  //Attempt to save the game, but if the state is too messed up it might fail
  try
    if fGameMode in [gmSingle, gmMulti] then
    begin
      Save('crashreport');
      AttachFile(SaveName('crashreport', 'sav', IsMultiplayer));
      AttachFile(SaveName('crashreport', 'bas', IsMultiplayer));
      AttachFile(SaveName('crashreport', 'rpl', IsMultiplayer));
    end;
  except
    on E : Exception do
      gLog.AddTime('Exception while trying to save game for crash report: '+E.ClassName+': '+E.Message);
  end;

  AttachFile(ExeDir + fMissionFile);
  AttachFile(ExeDir + ChangeFileExt(fMissionFile, '.map')); //Try to attach the map
  AttachFile(ExeDir + ChangeFileExt(fMissionFile, '.script')); //Try to attach the script

  for I := 1 to AUTOSAVE_COUNT do //All autosaves
  begin
    AttachFile(SaveName('autosave' + Int2Fix(I, 2), 'rpl', IsMultiplayer));
    AttachFile(SaveName('autosave' + Int2Fix(I, 2), 'bas', IsMultiplayer));
    AttachFile(SaveName('autosave' + Int2Fix(I, 2), 'sav', IsMultiplayer));
  end;

  gLog.AddTime('Crash report created');
end;
{$ENDIF}


//Occasional replay inconsistencies are a known bug, we don't need reports of it
procedure TKMGame.ReplayInconsistancy;
begin
  //Stop game from executing while the user views the message
  fIsPaused := True;
  gLog.AddTime('Replay failed a consistency check at tick '+IntToStr(fGameTickCount));
  if MessageDlg(gResTexts[TX_REPLAY_FAILED], mtWarning, [mbYes, mbNo], 0) <> mrYes then
    fGameApp.Stop(gr_Error, '')
  else
    fIsPaused := False;
end;


//Put the game on Hold for Victory screen
procedure TKMGame.GameHold(DoHold: Boolean; Msg: TGameResultMsg);
begin
  DoGameHold := false;
  fGamePlayInterface.ReleaseDirectionSelector; //In case of victory/defeat while moving troops
  fResource.Cursors.Cursor := kmc_Default;
  fViewport.ReleaseScrollKeys;
  PlayOnState := Msg;

  if DoHold then
  begin
    fIsPaused := True;
    fGamePlayInterface.ShowPlayMore(true, Msg);
  end else
    fIsPaused := False;
end;


procedure TKMGame.RequestGameHold(Msg:TGameResultMsg);
begin
  DoGameHold := true;
  DoGameHoldState := Msg;
end;


procedure TKMGame.PlayerVictory(aPlayerIndex: TPlayerIndex);
begin
  if aPlayerIndex = MySpectator.PlayerIndex then
    gSoundPlayer.Play(sfxn_Victory, 1, True); //Fade music

  if fGameMode = gmMulti then
  begin
    if aPlayerIndex = MySpectator.PlayerIndex then
    begin
      PlayOnState := gr_Win;
      fGamePlayInterface.ShowMPPlayMore(gr_Win);
    end;
  end
  else
    RequestGameHold(gr_Win);
end;


//Wrap for GameApp to access player color (needed for restart mission)
function TKMGame.PlayerColor: Cardinal;
begin
  Result := gPlayers[MySpectator.PlayerIndex].FlagColor;
end;


procedure TKMGame.PlayerDefeat(aPlayerIndex: TPlayerIndex);
begin
  //We have not thought of anything to display on players defeat in Replay
  if IsReplay then
    Exit;

  if aPlayerIndex = MySpectator.PlayerIndex then
    gSoundPlayer.Play(sfxn_Defeat, 1, True); //Fade music

  if fGameMode = gmMulti then
  begin
    fNetworking.PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_PLAYER_DEFEATED],
                                        [gPlayers[aPlayerIndex].PlayerName]));
    if aPlayerIndex = MySpectator.PlayerIndex then
    begin
      PlayOnState := gr_Defeat;
      fGamePlayInterface.ShowMPPlayMore(gr_Defeat);
    end;
  end
  else
  if aPlayerIndex = MySpectator.PlayerIndex then
    RequestGameHold(gr_Defeat);
end;


function TKMGame.PlayerLoc: Byte;
begin
  Result := MySpectator.PlayerIndex;
end;


//Display the overlay "Waiting for players"
//todo: Move to fNetworking and query GIP from there
procedure TKMGame.GameWaitingForNetwork(aWaiting: Boolean);
var WaitingPlayers: TStringList;
begin
  fWaitingForNetwork := aWaiting;

  WaitingPlayers := TStringList.Create;
  case fNetworking.NetGameState of
    lgs_Game, lgs_Reconnecting:
        //GIP is waiting for next tick
        TGameInputProcess_Multi(fGameInputProcess).GetWaitingPlayers(fGameTickCount+1, WaitingPlayers);
    lgs_Loading:
        //We are waiting during inital loading
        fNetworking.NetPlayers.GetNotReadyToPlayPlayers(WaitingPlayers);
    else
        Assert(false, 'GameWaitingForNetwork from wrong state '+GetEnumName(TypeInfo(TNetGameState), Integer(fNetworking.NetGameState)));
  end;

  fGamePlayInterface.ShowNetworkLag(aWaiting, WaitingPlayers, fNetworking.IsHost);
  WaitingPlayers.Free;
end;


//todo: Move to fNetworking and query GIP from there
procedure TKMGame.GameDropWaitingPlayers;
var WaitingPlayers: TStringList;
begin
  WaitingPlayers := TStringList.Create;
  case fNetworking.NetGameState of
    lgs_Game,lgs_Reconnecting:
        TGameInputProcess_Multi(fGameInputProcess).GetWaitingPlayers(fGameTickCount+1, WaitingPlayers); //GIP is waiting for next tick
    lgs_Loading:
        fNetworking.NetPlayers.GetNotReadyToPlayPlayers(WaitingPlayers); //We are waiting during inital loading
    else
        Assert(False); //Should not be waiting for players from any other GameState
  end;
  fNetworking.DropWaitingPlayers(WaitingPlayers);
  WaitingPlayers.Free;
end;


//Start MapEditor (empty map)
procedure TKMGame.GameStart(aSizeX, aSizeY: Integer);
var
  I: Integer;
begin
  fGameName := gResTexts[TX_MAPED_NEW_MISSION];

  fMissionFile := '';
  fSaveFile := '';

  gTerrain.MakeNewMap(aSizeX, aSizeY, True);
  fTerrainPainter := TKMTerrainPainter.Create;

  fMapEditor := TKMMapEditor.Create;
  gPlayers.AddPlayers(MAX_PLAYERS); //Create MAX players
  gPlayers[0].PlayerType := pt_Human; //Make Player1 human by default
  for I := 0 to gPlayers.Count - 1 do
    gPlayers[I].FogOfWar.RevealEverything;

  MySpectator := TKMSpectator.Create(0);
  MySpectator.FOWIndex := PLAYER_NONE;

  gPlayers.AfterMissionInit(false);

  if fGameMode = gmSingle then
    fGameInputProcess := TGameInputProcess_Single.Create(gipRecording);

  //When everything is ready we can update UI
  SyncUI;

  gLog.AddTime('Gameplay initialized', True);
end;


procedure TKMGame.AutoSave;
var
  I: Integer;
begin
  Save('autosave'); //Save to temp file

  //Delete last autosave and shift remaining by 1 position back
  DeleteFile(SaveName('autosave' + Int2Fix(AUTOSAVE_COUNT, 2), 'sav', IsMultiplayer));
  DeleteFile(SaveName('autosave' + Int2Fix(AUTOSAVE_COUNT, 2), 'rpl', IsMultiplayer));
  DeleteFile(SaveName('autosave' + Int2Fix(AUTOSAVE_COUNT, 2), 'bas', IsMultiplayer));
  for I := AUTOSAVE_COUNT downto 2 do // 03 to 01
  begin
    RenameFile(SaveName('autosave' + Int2Fix(I - 1, 2), 'sav', IsMultiplayer), SaveName('autosave' + Int2Fix(I, 2), 'sav', IsMultiplayer));
    RenameFile(SaveName('autosave' + Int2Fix(I - 1, 2), 'rpl', IsMultiplayer), SaveName('autosave' + Int2Fix(I, 2), 'rpl', IsMultiplayer));
    RenameFile(SaveName('autosave' + Int2Fix(I - 1, 2), 'bas', IsMultiplayer), SaveName('autosave' + Int2Fix(I, 2), 'bas', IsMultiplayer));
  end;

  //Rename temp to be first in list
  RenameFile(SaveName('autosave', 'sav', IsMultiplayer), SaveName('autosave01', 'sav', IsMultiplayer));
  RenameFile(SaveName('autosave', 'rpl', IsMultiplayer), SaveName('autosave01', 'rpl', IsMultiplayer));
  RenameFile(SaveName('autosave', 'bas', IsMultiplayer), SaveName('autosave01', 'bas', IsMultiplayer));
end;


//aPathName - full path to DAT file
procedure TKMGame.SaveMapEditor(const aPathName: string);
var
  I: Integer;
  fMissionParser: TMissionParserStandard;
begin
  if aPathName = '' then exit;

  //Prepare and save
  gPlayers.RemoveEmptyPlayers;

  ForceDirectories(ExtractFilePath(aPathName));
  gLog.AddTime('Saving from map editor: ' + aPathName);

  gTerrain.SaveToFile(ChangeFileExt(aPathName, '.map'));
  fTerrainPainter.SaveToFile(ChangeFileExt(aPathName, '.map'));
  fMissionParser := TMissionParserStandard.Create(mpm_Editor, false);
  fMissionParser.SaveDATFile(ChangeFileExt(aPathName, '.dat'));
  FreeAndNil(fMissionParser);

  fGameName := TruncateExt(ExtractFileName(aPathName));

  //Append empty players in place of removed ones
  gPlayers.AddPlayers(MAX_PLAYERS - gPlayers.Count);
  for I := 0 to gPlayers.Count - 1 do
    gPlayers[I].FogOfWar.RevealEverything;
end;


procedure TKMGame.Render(aRender: TRender);
begin
  fRenderPool.Render;

  aRender.SetRenderMode(rm2D);
  fActiveInterface.Paint;
end;


procedure TKMGame.RenderSelection;
begin
  fRenderPool.RenderSelection;
end;


//Restart the replay but keep the viewport position/zoom
procedure TKMGame.RestartReplay;
var
  OldCenter: TKMPointF;
  OldZoom: Single;
begin
  OldCenter := fViewport.Position;
  OldZoom := fViewport.Zoom;

  fGameApp.NewReplay(ChangeFileExt(ExeDir + fSaveFile, '.bas'));

  //Self is now destroyed, so we must access the NEW fGame object
  fGame.Viewport.Position := OldCenter;
  fGame.Viewport.Zoom := OldZoom;
end;


//TDateTime stores days/months/years as 1 and hours/minutes/seconds as fractions of a 1
//Treat 10 ticks as 1 sec irregardless of user-set pace
function TKMGame.MissionTime: TDateTime;
begin
  //Convert cardinal into TDateTime, where 1hour = 1/24 and so on..
  Result := fGameTickCount/24/60/60/10;
end;


function TKMGame.GetPeacetimeRemaining: TDateTime;
begin
  Result := Max(0, Int64(fGameOptions.Peacetime * 600) - fGameTickCount) / 24 / 60 / 60 / 10;
end;


//Tests whether time has past
function TKMGame.CheckTime(aTimeTicks: Cardinal): Boolean;
begin
  Result := (fGameTickCount >= aTimeTicks);
end;


function TKMGame.IsMapEditor: Boolean;
begin
  Result := fGameMode = gmMapEd;
end;


//We often need to see if game is MP
function TKMGame.IsMultiplayer: Boolean;
begin
  Result := fGameMode = gmMulti;
end;


function TKMGame.IsReplay: Boolean;
begin
  Result := fGameMode in [gmReplaySingle, gmReplayMulti];
end;


procedure TKMGame.ShowMessage(aKind: TKMMessageKind; aText: string; aLoc: TKMPoint);
begin
  fGamePlayInterface.MessageIssue(aKind, fTextMission.ParseTextMarkup(aText), aLoc);
end;


procedure TKMGame.ShowMessageFormatted(aKind: TKMMessageKind; aText: string; aLoc: TKMPoint; aParams: array of const);
var S: UnicodeString;
begin
  //We must parse for text markup before AND after running Format, since individual format
  //parameters can contain strings that need parsing (see Annie's Garden for an example)
  S := fTextMission.ParseTextMarkup(Format(fTextMission.ParseTextMarkup(aText), aParams));
  fGamePlayInterface.MessageIssue(aKind, S, aLoc);
end;


procedure TKMGame.ShowOverlay(aText: string);
begin
  fGamePlayInterface.SetScriptedOverlay(fTextMission.ParseTextMarkup(aText));
end;


procedure TKMGame.ShowOverlayFormatted(aText: string; aParams: array of const);
var S: UnicodeString;
begin
  //We must parse for text markup before AND after running Format, since individual format
  //parameters can contain strings that need parsing (see Annie's Garden for an example)
  S := fTextMission.ParseTextMarkup(Format(fTextMission.ParseTextMarkup(aText), aParams));
  fGamePlayInterface.SetScriptedOverlay(S);
end;


procedure TKMGame.OverlayAppend(aText: string);
begin
  fGamePlayInterface.AppendScriptedOverlay(fTextMission.ParseTextMarkup(aText));
end;


procedure TKMGame.OverlayAppendFormatted(aText: string; aParams: array of const);
var S: UnicodeString;
begin
  //We must parse for text markup before AND after running Format, since individual format
  //parameters can contain strings that need parsing (see Annie's Garden for an example)
  S := fTextMission.ParseTextMarkup(Format(fTextMission.ParseTextMarkup(aText), aParams));
  fGamePlayInterface.AppendScriptedOverlay(S);
end;


function TKMGame.IsPeaceTime: Boolean;
begin
  Result := not CheckTime(fGameOptions.Peacetime * 600);
end;


//Compute cursor position and store it in global variables
procedure TKMGame.UpdateGameCursor(X, Y: Integer; Shift: TShiftState);
begin
  with GameCursor do
  begin
    Pixel.X := X;
    Pixel.Y := Y;

    Float.X := fViewport.Position.X + (X-fViewport.ViewRect.Right/2-TOOLBAR_WIDTH/2)/CELL_SIZE_PX/fViewport.Zoom;
    Float.Y := fViewport.Position.Y + (Y-fViewport.ViewRect.Bottom/2)/CELL_SIZE_PX/fViewport.Zoom;
    Float.Y := gTerrain.ConvertCursorToMapCoord(Float.X,Float.Y);

    //Cursor cannot reach row MapY or column MapX, they're not part of the map (only used for vertex height)
    Cell.X := EnsureRange(round(Float.X+0.5), 1, gTerrain.MapX-1); //Cell below cursor in map bounds
    Cell.Y := EnsureRange(round(Float.Y+0.5), 1, gTerrain.MapY-1);

    ObjectUID := fRenderPool.GetSelectionUID(X, Y);

    SState := Shift;
  end;
end;


procedure TKMGame.UpdatePeaceTime;
var
  PeaceTicksRemaining: Cardinal;
begin
  PeaceTicksRemaining := Max(0, Int64((fGameOptions.Peacetime * 600)) - fGameTickCount);
  if (PeaceTicksRemaining = 1) and (fGameMode in [gmMulti,gmReplayMulti]) then
  begin
    gSoundPlayer.Play(sfxn_Peacetime, 1, True); //Fades music
    if fGameMode = gmMulti then
    begin
      SetGameSpeed(fGameOptions.SpeedAfterPT, False);
      fNetworking.PostLocalMessage(gResTexts[TX_MP_PEACETIME_OVER], false);
    end;
  end;
end;


function TKMGame.GetNewUID: Integer;
const
  //Prime numbers let us generate sequence of non-repeating values of max_value length
  max_value = 16777213;
  step = 8765423;
begin
  //UIDs have the following properties:
  // - allow -1 to indicate no UID
  // - fit within 24bit (we can use that much for RGB colorcoding)
  // - Start from 1, so that black colorcode can be detected and then re-mapped to -1

  fUIDTracker := (fUIDTracker + step) mod max_value + 1; //1..N range, 0 is nothing for colorpicker
  Result := fUIDTracker;
end;


procedure TKMGame.SetGameSpeed(aSpeed: Single; aToggle: Boolean);
begin
  Assert(aSpeed > 0);

  //MapEd always runs at x1
  if IsMapEditor then
  begin
    fGameSpeed := 1;
    fGameSpeedMultiplier := 1;
    fTimerGame.Interval := Round(fGameApp.GameSettings.SpeedPace / fGameSpeed);
    Exit;
  end;

  //Make the speed toggle between 1 and desired value
  if (aSpeed = fGameSpeed) and aToggle then
    fGameSpeed := 1
  else
    fGameSpeed := aSpeed;

  //When speed is above x5 we start to skip rendering frames
  //by doing several updates per timer tick
  if fGameSpeed > 5 then
  begin
    fGameSpeedMultiplier := Round(fGameSpeed / 4);
    fTimerGame.Interval := Round(fGameApp.GameSettings.SpeedPace / fGameSpeed * fGameSpeedMultiplier);
  end
  else
  begin
    fGameSpeedMultiplier := 1;
    fTimerGame.Interval := Round(fGameApp.GameSettings.SpeedPace / fGameSpeed);
  end;

  //don't show speed clock in MP since you can't turn it on/off
  if (fGamePlayInterface <> nil) and not IsMultiplayer then
    fGamePlayInterface.ShowClock(fGameSpeed);

  //Need to adjust the delay immediately in MP
  if IsMultiplayer and (fGameInputProcess <> nil) then
    TGameInputProcess_Multi(fGameInputProcess).AdjustDelay(fGameSpeed);
end;


//In replay mode we can step the game by exactly one frame and then pause again
procedure TKMGame.StepOneFrame;
begin
  Assert(fGameMode in [gmReplaySingle,gmReplayMulti], 'We can work step-by-step only in Replay');
  SetGameSpeed(1, False); //Make sure we step only one tick. Do not allow multiple updates in UpdateState loop
  fAdvanceFrame := True;
end;


//Saves the game in all its glory
procedure TKMGame.SaveGame(const aPathName: string);
var
  SaveStream: TKMemoryStream;
  fGameInfo: TKMGameInfo;
  i, NetIndex: integer;
begin
  gLog.AddTime('Saving game: ' + aPathName);

  if fGameMode in [gmMapEd, gmReplaySingle, gmReplayMulti] then
  begin
    Assert(false, 'Saving from wrong state');
    Exit;
  end;

  SaveStream := TKMemoryStream.Create;
  try
    fGameInfo := TKMGameInfo.Create;
    fGameInfo.Title := fGameName;
    fGameInfo.TickCount := fGameTickCount;
    fGameInfo.MissionMode := fMissionMode;
    fGameInfo.MapSizeX := gTerrain.MapX;
    fGameInfo.MapSizeY := gTerrain.MapY;
    fGameInfo.VictoryCondition := 'Win';
    fGameInfo.DefeatCondition := 'Lose';
    fGameInfo.PlayerCount := gPlayers.Count;
    for I := 0 to gPlayers.Count - 1 do
    begin
      if fNetworking <> nil then
        NetIndex := fNetworking.NetPlayers.PlayerIndexToLocal(I)
      else
        NetIndex := -1;

      if NetIndex = -1 then
      begin
        fGameInfo.Enabled[I] := False;
        fGameInfo.CanBeHuman[I] := False;
        fGameInfo.LocationName[I] := 'Unknown ' + IntToStr(I + 1);
        fGameInfo.PlayerTypes[I] := pt_Human;
        fGameInfo.ColorID[I] := 0;
        fGameInfo.Team[I] := 0;
      end else
      begin
        fGameInfo.Enabled[I] := True;
        fGameInfo.CanBeHuman[I] := fNetworking.NetPlayers[NetIndex].IsHuman;
        fGameInfo.LocationName[I] := fNetworking.NetPlayers[NetIndex].Nikname;
        fGameInfo.PlayerTypes[I] := fNetworking.NetPlayers[NetIndex].GetPlayerType;
        fGameInfo.ColorID[I] := fNetworking.NetPlayers[NetIndex].FlagColorID;
        fGameInfo.Team[I] := fNetworking.NetPlayers[NetIndex].Team;
      end;
    end;

    fGameInfo.Save(SaveStream);
    fGameInfo.Free;
    fGameOptions.Save(SaveStream);

    //Because some stuff is only saved in singleplayer we need to know whether it is included in this save,
    //so we can load multiplayer saves in single player and vice versa.
    SaveStream.Write(fGameMode = gmMulti);

    //Minimap is near the start so it can be accessed quickly
    //Each player in MP has his own minimap version ..
    if fGameMode <> gmMulti then
      fMinimap.SaveToStream(SaveStream);

    //We need to know which campaign to display after victory
    SaveStream.Write(fCampaignName);
    SaveStream.Write(fCampaignMap);

    //We need to know which mission/savegame to try to restart
    //(paths are relative and thus - MP safe)
    SaveStream.Write(fMissionFile);

    SaveStream.Write(fUIDTracker); //Units-Houses ID tracker
    SaveStream.Write(GetKaMSeed); //Include the random seed in the save file to ensure consistency in replays

    if fGameMode <> gmMulti then
      SaveStream.Write(PlayOnState, SizeOf(PlayOnState));

    gTerrain.Save(SaveStream); //Saves the map
    gPlayers.Save(SaveStream, fGameMode = gmMulti); //Saves all players properties individually
    if fGameMode <> gmMulti then
      MySpectator.Save(SaveStream);
    fAIFields.Save(SaveStream);
    fPathfinding.Save(SaveStream);
    gProjectiles.Save(SaveStream);
    fScripting.Save(SaveStream);

    fTextMission.Save(SaveStream);

    //Parameters that are not identical for all players should not be saved as we need saves to be
    //created identically on all player's computers. Eventually these things can go through the GIP

    //For multiplayer consistency we compare all saves CRCs, they should be created identical on all player's computers.
    if fGameMode <> gmMulti then
    begin
      //Viewport settings are unique for each player
      fViewport.Save(SaveStream);
      fGamePlayInterface.Save(SaveStream); //Saves message queue and school/barracks selected units
      //Don't include fGameSettings.Save it's not required for settings are Game-global, not mission
    end;

    //If we want stuff like the MessageStack and screen center to be stored in multiplayer saves,
    //we must send those "commands" through the GIP so all players know about them and they're in sync.
    //There is a comment in fGame.Load about MessageList on this topic.

    //Makes the folders incase they were deleted
    ForceDirectories(ExtractFilePath(aPathName));
    SaveStream.SaveToFile(aPathName); //Some 70ms for TPR7 map
  finally
    SaveStream.Free;
  end;

  gLog.AddTime('Saving game: ' + aPathName);
end;


//Saves game by provided name
procedure TKMGame.Save(const aName: string);
var
  PathName: string;
begin
  //Convert name to full path+name
  PathName := SaveName(aName, 'sav', IsMultiplayer);

  SaveGame(PathName);

  //Remember which savegame to try to restart (if game was not saved before)
  fSaveFile := ExtractRelativePath(ExeDir, PathName);

  //Copy basesave so we have a starting point for replay
  DeleteFile(SaveName(aName, 'bas', IsMultiplayer));
  CopyFile(PChar(SaveName('basesave', 'bas', IsMultiplayer)), PChar(SaveName(aName, 'bas', IsMultiplayer)), False);

  //Save replay queue
  gLog.AddTime('Saving replay info');
  fGameInputProcess.SaveToFile(ChangeFileExt(PathName, '.rpl'));

  gLog.AddTime('Saving game', True);
end;


procedure TKMGame.Load(const aPathName: string);
var
  LoadStream: TKMemoryStream;
  GameInfo: TKMGameInfo;
  LoadedSeed: Longint;
  SaveIsMultiplayer: Boolean;
begin
  fSaveFile := ChangeFileExt(ExtractRelativePath(ExeDir, aPathName), '.sav');

  gLog.AddTime('Loading game from: ' + aPathName);

  LoadStream := TKMemoryStream.Create;
  try

  if not FileExists(aPathName) then
    raise Exception.Create('Savegame could not be found');

  LoadStream.LoadFromFile(aPathName);

  //We need only few essential parts from GameInfo, the rest is duplicate from gTerrain and fPlayers
  GameInfo := TKMGameInfo.Create;
  try
    GameInfo.Load(LoadStream);
    fGameName := GameInfo.Title;
    fGameTickCount := GameInfo.TickCount;
    fMissionMode := GameInfo.MissionMode;
  finally
    FreeAndNil(GameInfo);
  end;

  fGameOptions.Load(LoadStream);

  //So we can allow loading of multiplayer saves in single player and vice versa we need to know which type THIS save is
  LoadStream.Read(SaveIsMultiplayer);
  if SaveIsMultiplayer and (fGameMode = gmReplaySingle) then
    fGameMode := gmReplayMulti; //We only know which it is once we've read the save file, so update it now

  //If the player loads a multiplayer save in singleplayer or replay mode, we require a mutex lock to prevent cheating
  //If we're loading in multiplayer mode we have already locked the mutex when entering multiplayer menu,
  //which is better than aborting loading in a multiplayer game (spoils it for everyone else too)
  if SaveIsMultiplayer and (fGameMode in [gmSingle, gmReplaySingle, gmReplayMulti]) then
    if fMain.LockMutex then
      fGameLockedMutex := True //Remember so we unlock it in Destroy
    else
      //Abort loading (exception will be caught in fGameApp and shown to the user)
      raise Exception.Create(gResTexts[TX_MULTIPLE_INSTANCES]);

  //Not used, (only stored for preview) but it's easiest way to skip past it
  if not SaveIsMultiplayer then
    fMinimap.LoadFromStream(LoadStream);

  //We need to know which campaign to display after victory
  LoadStream.Read(fCampaignName);
  LoadStream.Read(fCampaignMap);

  //We need to know which mission/savegame to try to restart
  //(paths are relative and thus - MP safe)
  LoadStream.Read(fMissionFile);

  LoadStream.Read(fUIDTracker);
  LoadStream.Read(LoadedSeed);

  if not SaveIsMultiplayer then
    LoadStream.Read(PlayOnState, SizeOf(PlayOnState));

  //Load the data into the game
  gTerrain.Load(LoadStream);

  gPlayers.Load(LoadStream);
  MySpectator := TKMSpectator.Create(0);
  if not SaveIsMultiplayer then
    MySpectator.Load(LoadStream);
  fAIFields.Load(LoadStream);
  fPathfinding.Load(LoadStream);
  gProjectiles.Load(LoadStream);
  fScripting.Load(LoadStream);

  fTextMission.Load(LoadStream);

  if IsReplay then
    MySpectator.FOWIndex := PLAYER_NONE; //Show all by default in replays

  //Multiplayer saves don't have this piece of information. Its valid only for MyPlayer
  //todo: Send all message commands through GIP (note: that means there will be a delay when you press delete)
  if not SaveIsMultiplayer then
  begin
    fViewport.Load(LoadStream);
    fGamePlayInterface.Load(LoadStream);
  end;


  if IsReplay then
    fGameInputProcess := TGameInputProcess_Single.Create(gipReplaying) //Replay
  else
    if fGameMode = gmMulti then
      fGameInputProcess := TGameInputProcess_Multi.Create(gipRecording, fNetworking) //Multiplayer
    else
      fGameInputProcess := TGameInputProcess_Single.Create(gipRecording); //Singleplayer

  fGameInputProcess.LoadFromFile(ChangeFileExt(aPathName, '.rpl'));

  gPlayers.SyncLoad; //Should parse all Unit-House ID references and replace them with actual pointers
  gTerrain.SyncLoad; //IsUnit values should be replaced with actual pointers

  if fGameMode = gmMulti then
    MultiplayerRig;

  SetKaMSeed(LoadedSeed);

  if fGameMode in [gmSingle, gmMulti] then
  begin
    DeleteFile(SaveName('basesave', 'bas', IsMultiplayer));
    CopyFile(PChar(ChangeFileExt(aPathName, '.bas')), PChar(SaveName('basesave', 'bas', IsMultiplayer)), False);
  end;

  //Repeat mission init if necessary
  if fGameTickCount = 0 then
    fScripting.ProcMissionStart;

  //When everything is ready we can update UI
  SyncUI;
  if SaveIsMultiplayer then //MP does not saves view position cos of save identity for all players
    fViewport.Position := KMPointF(gPlayers[MySpectator.PlayerIndex].CenterScreen);

  gLog.AddTime('Loading game', True);

  finally
    FreeAndNil(LoadStream);
  end;
end;


procedure TKMGame.UpdateGame(Sender: TObject);
var I: Integer;
begin
  //Some PCs seem to change 8087CW randomly between events like Timers and OnMouse*,
  //so we need to set it right before we do game logic processing
  Set8087CW($133F);

  if fIsPaused then Exit;

  case fGameMode of
    gmSingle, gmMulti:
                  if not (fGameMode = gmMulti) or (fNetworking.NetGameState <> lgs_Loading) then
                  for I := 1 to fGameSpeedMultiplier do
                  begin
                    if fGameInputProcess.CommandsConfirmed(fGameTickCount+1) then
                    begin
                      if DO_PERF_LOGGING then fPerfLog.EnterSection(psTick);

                      if fWaitingForNetwork then GameWaitingForNetwork(false); //No longer waiting for players
                      inc(fGameTickCount); //Thats our tick counter for gameplay events
                      if (fGameMode = gmMulti) then fNetworking.LastProcessedTick := fGameTickCount;
                      //Tell the master server about our game on the specific tick (host only)
                      if (fGameMode = gmMulti) and fNetworking.IsHost and (
                         ((fMissionMode = mm_Normal) and (fGameTickCount = ANNOUNCE_BUILD_MAP)) or
                         ((fMissionMode = mm_Tactic) and (fGameTickCount = ANNOUNCE_BATTLE_MAP))) then
                        fNetworking.ServerQuery.SendMapInfo(fGameName, fNetworking.NetPlayers.GetConnectedCount);

                      fScripting.UpdateState;
                      UpdatePeacetime; //Send warning messages about peacetime if required
                      gTerrain.UpdateState;
                      fAIFields.UpdateState(fGameTickCount);
                      gPlayers.UpdateState(fGameTickCount); //Quite slow
                      if fGame = nil then Exit; //Quit the update if game was stopped for some reason
                      MySpectator.UpdateState(fGameTickCount);
                      fPathfinding.UpdateState;
                      gProjectiles.UpdateState; //If game has stopped it's NIL

                      fGameInputProcess.RunningTimer(fGameTickCount); //GIP_Multi issues all commands for this tick
                      //In aggressive mode store a command every tick so we can find exactly when a replay mismatch occurs
                      if AGGRESSIVE_REPLAYS then
                        fGameInputProcess.CmdTemp(gic_TempDoNothing);

                      //Each 1min of gameplay time
                      //Don't autosave if the game was put on hold during this tick
                      if (fGameTickCount mod 600 = 0) and fGameApp.GameSettings.Autosave then
                        AutoSave;

                      //if (fGameTickCount mod 10 = 0) then
                      //  SaveGame(ExeDir + 'SavesLog'+PathDelim + int2fix(fGameTickCount, 6));

                      if DO_PERF_LOGGING then fPerfLog.LeaveSection(psTick);

                      //Break the for loop (if we are using speed up)
                      if DoGameHold then break;
                    end
                    else
                    begin
                      fGameInputProcess.WaitingForConfirmation(fGameTickCount);
                      if TGameInputProcess_Multi(fGameInputProcess).GetNumberConsecutiveWaits > 5 then
                        GameWaitingForNetwork(true);
                    end;
                    fGameInputProcess.UpdateState(fGameTickCount); //Do maintenance
                  end;
    gmReplaySingle,gmReplayMulti:
                  for I := 1 to fGameSpeedMultiplier do
                  begin
                    Inc(fGameTickCount); //Thats our tick counter for gameplay events
                    fScripting.UpdateState;
                    UpdatePeacetime; //Send warning messages about peacetime if required (peacetime sound should still be played in replays)
                    gTerrain.UpdateState;
                    fAIFields.UpdateState(fGameTickCount);
                    gPlayers.UpdateState(fGameTickCount); //Quite slow
                    if fGame = nil then Exit; //Quit the update if game was stopped for some reason
                    MySpectator.UpdateState(fGameTickCount);
                    fPathfinding.UpdateState;
                    gProjectiles.UpdateState; //If game has stopped it's NIL

                    //Issue stored commands
                    fGameInputProcess.ReplayTimer(fGameTickCount);
                    if fGame = nil then Exit; //Quit if the game was stopped by a replay mismatch
                    if not SkipReplayEndCheck and fGameInputProcess.ReplayEnded then
                      RequestGameHold(gr_ReplayEnd);

                    if fAdvanceFrame then
                    begin
                      fAdvanceFrame := False;
                      fIsPaused := True;
                    end;

                    //Break the for loop (if we are using speed up)
                    if DoGameHold then break;
                  end;
    gmMapEd:   begin
                  gTerrain.IncAnimStep;
                  gPlayers.IncAnimStep;
                end;
  end;

  fAlerts.UpdateState;

  if DoGameHold then GameHold(True, DoGameHoldState);
end;


procedure TKMGame.UpdateState(aGlobalTickCount: Cardinal);
begin
  if not fIsPaused then
    fActiveInterface.UpdateState(aGlobalTickCount);

  //Update minimap every 1000ms
  if aGlobalTickCount mod 10 = 0 then
    fMinimap.Update(False);

  if (aGlobalTickCount mod 10 = 0) and (fMapEditor <> nil) then
    fMapEditor.Update;
end;


//This is our real-time "thread", use it wisely
procedure TKMGame.UpdateStateIdle(aFrameTime: Cardinal);
begin
  if (not fIsPaused) or IsReplay then
    fViewport.UpdateStateIdle(aFrameTime); //Check to see if we need to scroll

  //Terrain should be updated in real time when user applies brushes
  if fTerrainPainter <> nil then
    fTerrainPainter.UpdateStateIdle;
end;


procedure TKMGame.SyncUI;
begin
  fMinimap.LoadFromTerrain(fAlerts);
  fMinimap.Update(False);

  if fGameMode = gmMapEd then
  begin
    fViewport.ResizeMap(gTerrain.MapX, gTerrain.MapY, 100 / CELL_SIZE_PX);
    fViewport.ResetZoom;
    fViewport.Position := KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2);

    fMapEditorInterface.SyncUI;
  end
  else
  begin
    fViewport.ResizeMap(gTerrain.MapX, gTerrain.MapY, gTerrain.TopHill / CELL_SIZE_PX);
    fViewport.ResetZoom;

    fGamePlayInterface.SetMinimap;
    fGamePlayInterface.SetMenuState(fMissionMode = mm_Tactic);
  end;
end;


function TKMGame.SaveName(const aName, aExt: string; aMultiPlayer: Boolean): string;
begin
  if aMultiPlayer then
    Result := ExeDir + 'SavesMP'+PathDelim + aName + '.' + aExt
  else
    Result := ExeDir + 'Saves'+PathDelim + aName + '.' + aExt;
end;


end.
