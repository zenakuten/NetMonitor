class MutNetMonitor extends Mutator;

var FileLog NMLog;
var bool bOpenedLog;
var config string LogTemplate;
var config bool bEnabled;
var config float Interval;


function PostBeginPlay()
{
    super.PostBeginPlay();
    if(Level.NetMode != NM_Standalone && bEnabled)
    {
        OpenLog();
        SetTimer(Interval, true);
    }
}

function Timer()
{
    if(bEnabled)
        LogAllPlayers();
}

function LogAllPlayers()
{
    local Controller C;
    local PlayerController PC;

    if (!Level.Game.IsInState('MatchInProgress'))
        return;

    for(C = Level.ControllerList;C!=None;C=C.NextController)
    {
        PC = PlayerController(C);
        if(PC != None)
        {
            LogPlayer(PC);
        }
    }
}

function LogPlayer(PlayerController PC)
{
    local PlayerReplicationInfo PRI;
    local string IP;
    PRI = PC.PlayerReplicationInfo;
    // make sure IP is legit (webadmin is also playercontroller...)
    IP = PC.GetPlayerNetworkAddress();
    if(PRI != None && IP != "")
    {
        // Timestamp,IP,Ping,PL
        NMLog.Logf(GetTimestamp()$","$left(IP,InStr(IP,":"))$","$PRI.PlayerName$","$PRI.Ping*4$","$PRI.PacketLoss);
    }
}

singular function OpenLog()
{
    if ( (LogTemplate!="") && (Level.NetMode!=NM_Standalone) )
    {
        if ( (NMLog!=None) && (!bOpenedLog) )
        {
            NMLog.OpenLog(BuildLogName());
            bOpenedLog=True;
            InitLog();
        }
        else if (NMLog==None)
        {
            NMLog=Spawn(class'Engine.FileLog');
            if (NMLog!=None)
            {
                NMLog.OpenLog(BuildLogName());
                bOpenedLog=True;
                InitLog();
            }
        }
    }
}

function InitLog()
{
    if ( (bOpenedLog) && (NMLog!=None) )
    {
        NMLog.Logf("Timestamp,IP,PlayerName,Ping,PacketLoss");
    }
    else
        log("[Error]: Could not init log", 'MutNetMonitor');
}

function string BuildLogName()
{
    local string R;
    R=LogTemplate;
    R=Repl(R, "%Map", GetCurMapName(), False);
    R=Repl(R, "%S", Right("00"$string(Level.Second), 2), False);
    R=Repl(R, "%Min", Right("00"$string(Level.Minute), 2), False);
    R=Repl(R, "%H", Right("00"$string(Level.Hour), 2), False);
    R=Repl(R, "%D", Right("00"$string(Level.Day), 2), False);
    R=Repl(R, "%Mon", Right("00"$string(Level.Month), 2), False);
    R=Repl(R, "%Y", Right("0000"$string(Level.Year), 4), False);
    return R;
}

function string GetTimestamp()
{
    local string temp;
    temp$=Right("0000"$string(Level.Year), 4);
    temp$="-"$Right("00"$string(Level.Month), 2);
    temp$="-"$Right("00"$string(Level.Day), 2);
    temp$="T";
    temp$=Right("00"$string(Level.Hour), 2);
    temp$=":"$Right("00"$string(Level.Minute), 2);
    temp$=":"$Right("00"$string(Level.Second), 2);
    return temp;
}

function string GetCurMapName()
{
    local string MapName;
    local int i;
    MapName=string(self);
    i=InStr(MapName,".");
    if (i>0)
    {
        MapName=Left(MapName, i);
        return MapName;
    }
    return "Could not find mapname!";
}

static function FillPlayInfo(PlayInfo PI)
{
    local byte weight;
    super.FillPlayInfo(PI);

    weight=1;
    PI.AddSetting("NetMonitor", "Interval", "net monitor interval in seconds", 0, Weight++, "Text", "8;0.0:10.0");
    PI.AddSetting("NetMonitor", "bEnabled", "net monitor enabled", 0, Weight++, "Check",,, False);
}

static event string GetDescriptionText(string PropName)
{
    switch(PropName)
    {
        case "Interval":         return "net monitor interval in seconds";
        case "bEnabled":         return "net monitor enabled (requires map restart)";
    }

    return super.GetDescriptionText(PropName);
}

defaultproperties
{
    bAlwaysTick=true
    bOpenedLog=false
    FriendlyName="Net Monitor 1.0"
    Description="Record a log of player network info"

    bEnabled=true
    LogTemplate="NMLog_%Map_%Mon_%D_%H_%Min"
    Interval=1.0
}

