// Mafia autosplitter and load remover by pitpo, Lembox, pudingus and Wafu
// FRE autosplitter by TheShalty

state("game", "1.0")
{
	bool isLoading1 : 0x272584;
	bool isLoaded : 0x2F9464, 0x40;		// returns 0 in profile selection
	bool isLoading3 : 0x2F94BC;			// returns 1 in main menu
	bool m1Cutscene : 0x25608C;
	bool inMission : 0x255360, 0x460, 0xB4, 0xDC;
	int subSegment : 0x27202C;
	byte finalCutscene : 0x256444;
	string2 language : 0x261C6C;		// returns cz, de, sp, it, ru, en
	string6 mission : 0x2F94A8, 0x0;
	string16 missionAlt : 0x2F94A8, 0x0;	// used for "submissions"
}

state("game", "1.2")
{
	bool isLoading1 : 0x2D4BFC;
	bool isLoaded : 0x247E1C, 0x40;
	bool isLoading3 : 0x247E74;
	bool m1Cutscene : 0x23D730;
	bool inMission : 0x23D2BC, 0x460, 0xB4, 0xDC;
	int subSegment : 0x2D46A4;
	byte finalCutscene : 0x2BDD7C;
	string2 language : 0x2C42C4;
	string6 mission : 0x247E60, 0x0;
	string16 missionAlt : 0x247E60, 0x0;
}

init
{
	if (modules.First().ModuleMemorySize == 3158016) {
		version = "1.0";
	}
	else if (modules.First().ModuleMemorySize == 2993526) {
		version = "1.2";
	}

	vars.setFinalCutscene = false; // needed because language variable is not directly set with the game starting
  vars.finalSubSegment = settings["hoe"] ? 563 : 561;
}

startup
{
  settings.Add("hoe", false, "Hell on Earth mod");
  
	settings.Add("fairplay", false, "Split after night segment in Fairplay");
	settings.Add("sarah", true, "Split after Sarah");
	settings.Add("whore", true, "Split after Whore");
  settings.Add("checkpoint-start", false, "Start timer by loading any checkpoint");
  
	settings.Add("checkpoint_splits", false, "Split checkpoints rather than entire missions");
	settings.Add("molotov-bar", false, "Split Molotov Party - Salieri Bar", "checkpoint_splits");
	settings.Add("molotov-morello", true, "Split Molotov Party - Morello's Bar", "checkpoint_splits");
	settings.Add("sarah-bar", false, "Split Sarah - Salieri Bar", "checkpoint_splits");
	settings.Add("get-used-chase", false, "Split Better Get Used To It - Chase (HoE: Service Station 2)", "checkpoint_splits");
	settings.Add("omerta-city2", true, "Split Omerta - City 2", "checkpoint_splits");
	settings.Add("visit-rich-city", true, "Split Visiting Rich People - City", "checkpoint_splits");
	settings.Add("deal-bar", false, "Split A Great Deal! - Salieri Bar", "checkpoint_splits");
	settings.Add("deal-return", false, "Split A Great Deal! - Back At The Bar", "checkpoint_splits");
	settings.Add("bastard-fireworks", true, "Split You Lucky Bastard! - Fireworks", "checkpoint_splits");
	settings.Add("art-dies-city", true, "Split The Death Of Art - City", "checkpoint_splits");
	
	vars.crash = false;
	vars.lastMission = "";
	vars.fromExtrem = false;
	vars.lastSubSegment = 0;
	vars.nextMandatoryCheckpointIndex = 1;
  
	vars.mandatoryCheckpoints = new int[] {
		000, 005, 010, 015, 020, 025, 030, 035, 040, 045, 050, 055, 060, 070, 075, 080, 085, 090, 095, 100, 105, 110, 115,
		125, 130, 131, 135, 140, 146, 150, 155, 165, 170, 185, 190, 195, 197, 200, 205, 225, 230, 240, 243, 245, 265, 270, 
    275, 277, 280, 285, 290, 295, 310, 315, 320, 325, 330, 335, 340, 345, 350, 355, 360, 370, 372, 375, 380, 385, 390, 
    410, 415, 425, 435, 455, 460, 465, 466, 470, 490, 495, 500, 505, 510, 520, 525, 535, 540, 545, 550, 560, 561, 563
	};

	vars.skippableCheckpoints = new Dictionary<int, string>() {
		{040, "molotov-bar"}, {045, "molotov-morello"}, {130, "sarah-bar"}, {146, "get-used-chase"}, {235, "omerta-city2"}, 
		{270, "visit-rich-city"}, {290, "deal-bar"}, {300, "deal-return"}, {360, "bastard-fireworks"}, {550, "art-dies-city"}
	};
}

update
{
	if (!vars.setFinalCutscene && current.language != "") {
		if (current.language == "cz") vars.finalCutscene = 2;
		else if (current.language == "de") vars.finalCutscene = 3;
		else if (current.language == "sp") vars.finalCutscene = 1;
		else vars.finalCutscene = 0; 
		vars.setFinalCutscene = true;
	}
	
	if (version == "") return;		// If version is unknown, don't do anything (without it, it'd default to "1.0" version)

	if (current.mission != null) {
		vars.lastMission = current.mission;
	}

	if (old.mission == "00menu" && current.mission != "00menu") {
		vars.crash = false;
		timer.IsGameTimePaused = false;
	}
}

start
{
  if ((!old.m1Cutscene && current.m1Cutscene && current.mission == "mise01") || (((current.mission == "extrem" && !current.inMission) || (settings["checkpoint-start"]) && current.subSegment > 0) && old.isLoading3 && !current.isLoading3)) {
		vars.lastSubSegment = current.subSegment;
		vars.nextMandatoryCheckpointIndex = 1;
		return true;
	}
}

// Reset timer on "An Offer You Can't Refuse" load (you can comment this section out if you don't want this feature)
reset
{
	return (current.mission == "mise01" && ((old.isLoading1 && !current.isLoading1) || (!old.isLoading3 && current.isLoading3)));
}

// Split for every mission change (at the very beginning of every loading)
split
{
	if (current.mission == null) return;  // gets rid of null reference expections in debugview
	if (current.mission.Contains("mise") && old.mission != "00menu") {
		// Final split
    if (old.subSegment == vars.finalSubSegment && current.subSegment == vars.finalSubSegment) {
			return (old.finalCutscene <= vars.finalCutscene && current.finalCutscene > vars.finalCutscene);
		}

		// Split individual checkpoints
		else if (settings["checkpoint_splits"]) {
      if (vars.lastSubSegment < current.subSegment && (settings["checkpoint-start"] || current.subSegment <= vars.mandatoryCheckpoints[vars.nextMandatoryCheckpointIndex])) {
				vars.lastSubSegment = current.subSegment;
				if (current.subSegment == vars.mandatoryCheckpoints[vars.nextMandatoryCheckpointIndex]) {
					vars.nextMandatoryCheckpointIndex++;
				}
				foreach(KeyValuePair<int, string> entry in vars.skippableCheckpoints) {
					if (current.subSegment == entry.Key && !settings[entry.Value]) {
						return false;
					}
				}
				return settings["hoe"] || (current.subSegment != 145 && current.subSegment != 430); // don't split 'Better Get Used To It - Service Station' and 'Creme De La Creme - The Airport'
			}
			return false;
		}

		// Don't split on these mission changes
		else if (current.mission == "mise01") return false;

		// Split during Fairplay
		else if (current.mission == "mise06") {
			return (old.mission == "mise05" && settings["fairplay"]);
		}

		// Split after Sarah
		else if (current.missionAlt == "mise07b-saliery") {
			return (old.missionAlt == "mise07-sara" && settings["sarah"]);
		}

		// Split after The Whore
		else if (current.missionAlt == "mise08-kostel") {
			return (old.missionAlt == "mise08-hotel" && settings["whore"]);
		}
    
		// Split for any other mission
		return (old.mission != current.mission);
	}
	else if (old.missionAlt == "mise20-galery" && current.missionAlt == "FMV KONEC") {
		return true;
	}
	else {
		return (current.mission == "extrem" && old.inMission && !current.inMission && !current.isLoading3 && !current.isLoading1 && current.isLoaded); // split in case of FRE else false
	}
}

// Load remover  (you can comment this section out if you don't want this feature)
isLoading
{
	if (!vars.crash) {
		// FRE is real time only

		if (current.mission == "extrem") {
			return false;
		}
		else if (current.mission == "00menu") {
			if (old.mission == "extrem") vars.fromExtrem = true;

			return (current.isLoading1 && !vars.fromExtrem);
		}
		else {
			vars.fromExtrem = false;
			return (current.isLoading1 || !current.isLoaded || current.isLoading3);
		}
	}
}

exit
{
	if (vars.lastMission != "extrem") {
		timer.IsGameTimePaused = true;
	}
	vars.crash = true;	
}
