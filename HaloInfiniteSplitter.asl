// Halo Infinite autosplitter by LiamTrader
// Tick-based with cutscenes removed
//
// Code from:
//     - Jujstme
//     - Dyse
//     - Distro
//     - LiamTrader
//     - cocopuffs239
//
// Made possible by contributions from the HaloRuns Community

state("HaloInfinite") {
    //Load Removal
    long tickrateCounter: "HaloInfinite.exe", 0x3E95BF8; // tickrate counter. Starts when game starts. Increases by 60 per second (in theory). Pauses during stutters and loads and pause menu.
    byte inMenu: "HaloInfinite.exe", 0x463ED04; // 4 when in-game. 0-3 when in the menu. hops to 4 somewhere during the splash screen.
    byte splashScreen: "HaloInfinite.exe", 0x46B6684; // value is non zero while in splash screen. hops somewhere between 1 and 5. gameplay control might be possible during 4 in splash screen. NOT SURE. will go safe and pause time unless zero.
    int resetTickrate: "HaloInfinite.exe", 0x413EB60, 0xCF8; // tickrate counter that starts when you start a level. We will use this for resets. If below 30, then reset.
    // string255 map: "HaloInfinite.exe", 0x4931B60; // Current map name in memory. Self explanatory.
}

startup
{
    // Long list of settings we want to implement in the autosplitter.
    // Settings that have "split" in their tooltip will be considered for the autosplitting dictionary
    // Format:
    //   { parent, settingID, settingText, settingToolTip, defaultState }

    // These are used for the IGT tracking
    vars.ticksPerSecond = TimeSpan.TicksPerSecond/60.0;
    vars.gameTime = 0;

    dynamic[,] Settings =
    {
        { null, "startOnWarship", "Start the timer only when gaining control on Warship Gbraakon", null, false },
        { null, "cutsplit", "Split on start", null, false },
        { null, "IL", "IL Splitting Mode", "Will trigger a split on the start of cutscenes", false },
        { null, "autosplitting", "Auto Splitting", null, true },
            { "autosplitting", "warshipGbraakon", "Warship Gbraakon", "Will trigger a split after completing the mission \"Warship Gbraakon\".", true },
            { "autosplitting", "foundation", "Foundation", "Will trigger a split after completing the mission \"Foundation\".", true },
            { "autosplitting", "outpostTremonius", "Outpost Tremonius", "Will trigger a split after taking control of Outpost Tremonius.", true },
            { "autosplitting", "FOBGolf", "FOB Golf", "Will trigger a split after taking control of FOB Golf.", true },
            { "autosplitting", "tower", "Tower", "Will trigger a split after freeing Spartan Griffin upon completion of the mission \"The Tower\".", true },
            { "autosplitting", "excavationSite", "Excavation Site", null, true },
                { "excavationSite", "reachTheDigSite", "Reach the Excavation Site", "Will trigger a split after the first cutscene in the excavation site.", true },
                { "excavationSite", "bassus", "Bassus", "Will trigger a split upon entering the Conservatory, after Bassus' defeat.", true },
            { "autosplitting", "conservatory", "Conservatory", "Will trigger a split after completing the mission \"Conservatory\".", true },
            { "autosplitting", "spire", "Spire", null, true},
                { "spire", "spireApproach", "Approach the command spire", "Will trigger a split upon entering the first spire.", true },
                { "spire", "adjutantResolution", "Adjutant Resolution", "Will trigger a split after defeting Adjuvant resolution and dectivating the spire.", true },
            { "autosplitting", "pelicanDown", "Pelican Down", null, true },
                { "pelicanDown", "EastAAGun", "East AA Gun", "Will trigger a split upon destruction of the East AA Gun.", true },
                { "pelicanDown", "NorthAAGun", "North AA Gun", "Will trigger a split upon destruction of the North AA Gun.", true },
                { "pelicanDown", "WestAAGun", "West AA Gun", "Will trigger a split upon destruction of the West AA Gun.", true },
                { "pelicanDown", "spartanKillers", "Hyperius and Tovarus", "Will trigger a split when finding Echo-216 after defeting the Spartan killers Hyperius and Tovarus.", true },
            { "autosplitting", "sequence", "The Sequence", null, true },
                { "sequence", "easternBeacon", "Eastern Beacon", "Will trigger a split after activating the Eastern Beacon.", true },
                { "sequence", "southernBeacon", "Southern Beacon", "Will trigger a split after activating the Southern Beacon.", true },
                { "sequence", "northernBeacon", "Northern Beacon", "Will trigger a split after activating the Northern Beacon.", true },
                { "sequence", "southwesternBeacon", "Southwestern Beacon", "Will trigger a split after activating the Southwestern Beacon.", true },
                { "sequence", "enterNexus", "Enter the Nexus", "Will trigger a split upon entering the Nexus.", true },
            { "autosplitting", "nexus", "Nexus", "Will trigger a split upon completing the mission \"Nexus\".", true },
            { "autosplitting", "commandSpire", "Command Spire", null, true },
                { "commandSpire", "reachTheTop", "Reach the Top", "Will trigger a split upon reaching the top of the Command Spire.", true },
                { "commandSpire", "deactivateCommandSpire", "Deactivate the Command Spire", "Will trigger a split after deactivation of the Command Spire.", true },
            { "autosplitting", "repository", "Repository", "Will trigger a split upon completion of the mission \"Repository\".", true },
            { "autosplitting", "road", "Road", "Will trigger a split upon entering the House of Reckoning.", true },
            { "autosplitting", "houseOfReckoning", "House of Reckoning", "Will trigger a split upon completion of the House of Reckoning.", true },
            { "autosplitting", "silentAuditorium", "Silent Auditorium", "Will trigger a split upon defeat of the Harbringer.", true }
    };


for (int i = 0; i < Settings.GetLength(0); i++)
{
    settings.Add(Settings[i, 1], Settings[i, 4], Settings[i, 2], Settings[i, 0]);
    if (!string.IsNullOrEmpty(Settings[i, 3]))
        settings.SetToolTip(Settings[i, 1], Settings[i, 3]);
}



    // Define a new ExpandoObject to store some named constants we will need later on
    vars.Maps = new ExpandoObject();
    vars.Maps.MainMenu         = "mainmenu";
    vars.Maps.WarshipGbraakon  = "dungeon_banished_ship";
    vars.Maps.Foundation       = "dungeon_underbelly";
    vars.Maps.ZetaHalo         = "island01";
    vars.Maps.Conservatory     = "dungeon_forerunner_dallas";
    vars.Maps.Spire01          = "dungeon_spire_01";
    vars.Maps.Nexus            = "dungeon_forerunner_houston";
    vars.Maps.Spire02          = "dungeon_spire_02";
    vars.Maps.Repository       = "dungeon_forerunner_austin";
    vars.Maps.HouseOfReckoning = "dungeon_boss_hq_interior";
    vars.Maps.SilentAuditorium = "dungeon_cortana_palace";

    // SplitBools: a dictionary of booleans that will tell us if we met the conditions to split at a certain point during the run
    vars.SplitBools = new Dictionary<string, Func<bool>>{
        { "warshipGbraakon", () => !vars.AlreadyTriggeredSplits["warshipGbraakon"] && vars.Map.Old == vars.Maps.WarshipGbraakon && vars.Map.Current == vars.Maps.Foundation },
        { "foundation", () => !vars.AlreadyTriggeredSplits["foundation"] && vars.Map.Old == vars.Maps.Foundation && vars.Map.Current == vars.Maps.ZetaHalo },
        { "outpostTremonius", () => !vars.AlreadyTriggeredSplits["outpostTremonius"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["OutpostTremonius"].Changed && vars.watchers["OutpostTremonius"].Current == 6 },
        { "FOBGolf", () => !vars.AlreadyTriggeredSplits["FOBGolf"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["FOBGolf"].Changed && vars.watchers["FOBGolf"].Current == 10 },
        { "tower", () => !vars.AlreadyTriggeredSplits["tower"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["Tower"].Changed && vars.watchers["Tower"].Current == 10 },
        { "reachTheDigSite", () => !vars.AlreadyTriggeredSplits["reachTheDigSite"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["TravelToDigSite"].Changed && vars.watchers["TravelToDigSite"].Current == 10 },
        { "bassus", () => !vars.AlreadyTriggeredSplits["bassus"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Conservatory },
        { "conservatory", () => !vars.AlreadyTriggeredSplits["conservatory"] && vars.Map.Old == vars.Maps.Conservatory && vars.Map.Current == vars.Maps.ZetaHalo },
        { "spireApproach", () => !vars.AlreadyTriggeredSplits["spireApproach"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Spire01 },
        { "adjutantResolution", () => !vars.AlreadyTriggeredSplits["adjutantResolution"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["Spire"].Changed && vars.watchers["Spire"].Current == 10 },
        { "EastAAGun", () => !vars.AlreadyTriggeredSplits["EastAAGun"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["EastAAGun"].Changed && vars.watchers["EastAAGun"].Current == 10 },
        { "NorthAAGun", () => !vars.AlreadyTriggeredSplits["NorthAAGun"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["NorthAAGun"].Changed && vars.watchers["NorthAAGun"].Current == 10 },
        { "WestAAGun", () => !vars.AlreadyTriggeredSplits["WestAAGun"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["WestAAGun"].Changed && vars.watchers["WestAAGun"].Current == 10 },
        { "spartanKillers", () => !vars.AlreadyTriggeredSplits["spartanKillers"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["EastAAGun"].Old == 10 && vars.watchers["NorthAAGun"].Old == 10 && vars.watchers["WestAAGun"].Old == 10 && vars.watchers["PelicanSpartanKillers"].Changed && vars.watchers["PelicanSpartanKillers"].Current == 10 },
        { "easternBeacon", () => !vars.AlreadyTriggeredSplits["easternBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceEasternBeacon"].Changed && vars.watchers["SequenceEasternBeacon"].Current == 10 },
        { "southernBeacon", () => !vars.AlreadyTriggeredSplits["southernBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceSouthernBeacon"].Changed && vars.watchers["SequenceSouthernBeacon"].Current == 10 },
        { "northernBeacon", () => !vars.AlreadyTriggeredSplits["northernBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceNorthernBeacon"].Changed && vars.watchers["SequenceNorthernBeacon"].Current == 10 },
        { "southwesternBeacon", () => !vars.AlreadyTriggeredSplits["southwesternBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceSouthwesternBeacon"].Changed && vars.watchers["SequenceSouthwesternBeacon"].Current == 10 },
        { "enterNexus", () => !vars.AlreadyTriggeredSplits["enterNexus"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Nexus },
        { "nexus", () => !vars.AlreadyTriggeredSplits["nexus"] && vars.Map.Old == vars.Maps.Nexus && vars.Map.Current == vars.Maps.Spire02 },
        { "reachTheTop", () => !vars.AlreadyTriggeredSplits["reachTheTop"] && vars.Map.Old == vars.Maps.Spire02 && vars.Map.Current == vars.Maps.ZetaHalo },
        { "deactivateCommandSpire", () => !vars.AlreadyTriggeredSplits["deactivateCommandSpire"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Repository },
        { "repository", () => !vars.AlreadyTriggeredSplits["repository"] && vars.Map.Old == vars.Maps.Repository && vars.Map.Current == vars.Maps.ZetaHalo },
        { "road", () => !vars.AlreadyTriggeredSplits["road"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.HouseOfReckoning },
        { "houseOfReckoning", () => !vars.AlreadyTriggeredSplits["houseOfReckoning"] && vars.Map.Old == vars.Maps.HouseOfReckoning && vars.Map.Current == vars.Maps.SilentAuditorium },
        { "silentAuditorium", () => !vars.AlreadyTriggeredSplits["silentAuditorium"] && vars.Map.Current == vars.Maps.SilentAuditorium && vars.watchers["SilentAuditorium"].Changed && vars.watchers["SilentAuditorium"].Current == 10 }
    };

    // AlreadyTriggeredSplits: pretty much self-explanatory, it records if we already triggered a certain splits, avoiding unwanted double splitting
    vars.AlreadyTriggeredSplits = new Dictionary<string, bool>();
    foreach (var entry in vars.SplitBools.Keys) vars.AlreadyTriggeredSplits.Add(entry, false);

    // Define a GetCurrentMap function we use to get the current map name
    vars.GetCurrentMap = (Func<string>)(() => vars.watchers["StatusString"].Current.Substring(vars.watchers["StatusString"].Current.LastIndexOf("\\") + 1));

    // Define load state
    vars.GetLoadState = (Func<bool>)( () =>
            vars.watchers["LoadStatus"].Current ||
            !vars.watchers["DoNotFreeze"].Current ||
            vars.watchers["LoadStatus2"].Current < 4 ||
            vars.watchers["LoadSomething"].Current ||
            vars.watchers["InCutscene"].Current ||
            vars.watchers["LoadSplashScreen"].Current >= 1 && vars.watchers["LoadSplashScreen"].Current <= 4
            );

    // Additional vars we use in place of the old and current state variables
    vars.IsLoading = new ExpandoObject();
    vars.IsLoading.Old = false;
    vars.IsLoading.Current = false;

    vars.Map = new ExpandoObject();
    vars.Map.Old = string.Empty;
    vars.Map.Current = string.Empty;

    vars.cutsplit = false;
}

init
{
    var ArbiterModuleSize = modules.FirstOrDefault(x => x.ModuleName == "Arbiter.dll").ModuleMemorySize;
    vars.IsAutosplitterEnabled = true;

    vars.watchers = new MemoryWatcherList();
    vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x4648ADC)) { Name = "LoadStatus" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x463ED04)) { Name = "LoadStatus2" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x46B6684)) { Name = "LoadSplashScreen" });
    vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x41E6B62)) { Name = "LoadSomething" });
    vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x4AF26B0)) { Name = "InCutscene" });
    vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x46B5341)) { Name = "DoNotFreeze" });
    vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x41D47B1)) { Name = "IsLoadingInCutscene" });
    vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x4931B60), 255) { Name = "StatusString" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB5558)) { Name = "OutpostTremonius" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB746C)) { Name = "FOBGolf" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB55B0)) { Name = "Tower" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB72BC)) { Name = "TravelToDigSite" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB5308)) { Name = "Spire" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7344)) { Name = "EastAAGun" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7354)) { Name = "NorthAAGun" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7364)) { Name = "WestAAGun" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7384)) { Name = "PelicanSpartanKillers" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9370)) { Name = "SequenceNorthernBeacon" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9378)) { Name = "SequenceSouthernBeacon" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9380)) { Name = "SequenceEasternBeacon" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB740C)) { Name = "SilentAuditorium" });
}

update
{
    // If we explicitly disabled the autosplitter, return false
    if (!vars.IsAutosplitterEnabled) return false;

    // Update the watchers
    vars.watchers.UpdateAll(game);

    // Update our custom state variables
    vars.Map.Old = vars.Map.Current;
    vars.Map.Current = vars.GetCurrentMap();

    vars.IsLoading.Old = vars.IsLoading.Current;
    vars.IsLoading.Current = vars.GetLoadState();

    // If the timer isn't running (eg. a run reset), reset the splits dictionary
    if (timer.CurrentPhase == TimerPhase.NotRunning && ((Dictionary<string, bool>)(vars.AlreadyTriggeredSplits)).Any(x => x.Value))
    {
        foreach (var s in new List<string>(vars.AlreadyTriggeredSplits.Keys))
            vars.AlreadyTriggeredSplits[s] = false;
    }
}

gameTime {
    if (current.inMenu != 4 || (current.splashScreen >= 1 && current.splashScreen <= 4) || (vars.IsLoading.Current || vars.watchers["IsLoadingInCutscene"].Current)) { return; }
    vars.gameTime += current.tickrateCounter - old.tickrateCounter;
    return TimeSpan.FromTicks((long)(vars.gameTime * vars.ticksPerSecond));
}

isLoading
{
    //return vars.IsLoading.Current || vars.watchers["IsLoadingInCutscene"].Current;
    return true; // we do IGT tracking solely. We can always return true here and only read the IGT.
}

split
{
    if (settings["IL"])
    {
        if (((vars.watchers["InCutscene"].Current != vars.watchers["InCutscene"].Old && vars.watchers["InCutscene"].Current == true) || vars.Map.Current != vars.Map.Old) && vars.Map.Current != "mainmenu")
        {
            return true;
        }
    }
    else
    {
        foreach (var entry in vars.SplitBools)
        {
            if (entry.Value())
            {
                vars.AlreadyTriggeredSplits[entry.Key] = true;
                if (settings[entry.Key])
                {
                    return true;
                } 
            }
        }
    }
    
    if (settings["cutsplit"] && vars.cutsplit)
    {
        vars.cutsplit = false;
        return true;
    }
}

start
{
    if (settings["IL"] == true && vars.Map.Current != vars.Maps.MainMenu && vars.IsLoading.Current != vars.IsLoading.Old)
    {  
        vars.gameTime = timer.Run.Offset.Ticks / vars.ticksPerSecond;
        return true;
    }
    else
    {
        bool start = settings["startOnWarship"]
                ? vars.Map.Current == vars.Maps.WarshipGbraakon && vars.watchers["WarshipGbraakonStartTrigger"].Current == 3 && !vars.IsLoading.Current
                : vars.Map.Current == vars.Maps.WarshipGbraakon && vars.IsLoading.Old && !vars.IsLoading.Current && vars.watchers["WarshipGbraakonStartTrigger"].Current == 0;
        if (start) {
            vars.gameTime = timer.Run.Offset.Ticks / vars.ticksPerSecond;
            return true;
        }
    }
}

reset
{
    if (vars.Map.Current == vars.Maps.WarshipGbraakon && current.resetTickrate <= 15)
    {
        vars.gameTime = timer.Run.Offset.Ticks / vars.ticksPerSecond;
        return true;
    }
}

onStart
{
    vars.gameTime = timer.Run.Offset.Ticks / vars.ticksPerSecond;
    vars.cutsplit = true;
}

onReset
{
    vars.gameTime = timer.Run.Offset.Ticks / vars.ticksPerSecond;
}

exit
{
    timer.IsGameTimePaused = true;
}
