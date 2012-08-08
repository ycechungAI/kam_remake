unit KM_AISetup;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils, SysUtils,
    KM_CommonClasses, KM_Points;


type
  TKMPlayerAISetup = class
    Aggressiveness: Integer; //-1 means not used or default
    AutoBuild: Boolean;
    AutoRepair: Boolean;
    EquipRate: Word; //Number of ticks between soldiers being equipped
    MaxSoldiers: Integer; //-1 means not used or default
    RecruitDelay: Cardinal; //Recruits (for barracks) can only be trained after this many ticks
    RecruitFactor: Byte;
    SerfFactor: Byte;
    StartPosition: TKMPoint; //Defines roughly where to defend and build around
    TownDefence: Integer; //-1 means not used or default
    WorkerFactor: Byte;

    Strong: Boolean;
    Wooden: Boolean;

    constructor Create;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation
uses KM_Utils;


{ TKMPlayerAISetup }
constructor TKMPlayerAISetup.Create;
begin
  inherited;

  //TSK/TPR properties
  Aggressiveness := 100; //No idea what the default for this is, it's barely used
  AutoBuild := True; //In KaM it is On by default, and most missions turn it off
  AutoRepair := False; //In KaM it is Off by default
  EquipRate := 1000; //Measured in KaM: AI equips 1 soldier every ~100 seconds
  MaxSoldiers := High(MaxSoldiers); //No limit by default
  WorkerFactor := 6;
  RecruitFactor := 5; //This means the number in the barracks, watchtowers are counted seperately
  RecruitDelay := 0; //Can train at start
  SerfFactor := 10; //Means 1 serf per building
  StartPosition := KMPoint(1,1);
  TownDefence := 100; //In KaM 100 is standard, although we don't completely understand this command

  //Remake properties
  Strong := (KaMRandom > 0.5);
  Wooden := (KaMRandom > 0.5);
end;


procedure TKMPlayerAISetup.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(Aggressiveness);
  SaveStream.Write(AutoBuild);
  SaveStream.Write(AutoRepair);
  SaveStream.Write(EquipRate);
  SaveStream.Write(MaxSoldiers);
  SaveStream.Write(RecruitDelay);
  SaveStream.Write(RecruitFactor);
  SaveStream.Write(SerfFactor);
  SaveStream.Write(StartPosition);
  SaveStream.Write(TownDefence);
  SaveStream.Write(WorkerFactor);

  SaveStream.Write(Strong);
  SaveStream.Write(Wooden);
end;


procedure TKMPlayerAISetup.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(Aggressiveness);
  LoadStream.Read(AutoBuild);
  LoadStream.Read(AutoRepair);
  LoadStream.Read(EquipRate);
  LoadStream.Read(MaxSoldiers);
  LoadStream.Read(RecruitDelay);
  LoadStream.Read(RecruitFactor);
  LoadStream.Read(SerfFactor);
  LoadStream.Read(StartPosition);
  LoadStream.Read(TownDefence);
  LoadStream.Read(WorkerFactor);

  LoadStream.Read(Strong);
  LoadStream.Read(Wooden);
end;


end.